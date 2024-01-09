# Планировщик обвноления просмотра постов в БД
class UpdatePostsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical_queue, retry: 0

  def perform 
    # Обновление по 10к штук
    count_batch = (Redis0.llen('update_posts_data') / 10000.0).ceil

    count_batch.times do
      values = Redis0.lrange('update_posts_data', 0, 99999)
      
      update_values = values.map do |v| 
        val = JSON.parse(v)
        "(#{[ActiveRecord::Base.connection.quote(val[0]),
         ActiveRecord::Base.connection.quote(val[1]),
         ActiveRecord::Base.connection.quote(val[2]),
         "#{ActiveRecord::Base.connection.quote(val[3].to_json)}",
         ActiveRecord::Base.connection.quote(val[4]),
         ActiveRecord::Base.connection.quote(val[5]),
         ActiveRecord::Base.connection.quote(val[6]),
         ActiveRecord::Base.connection.quote(val[7]),
         ActiveRecord::Base.connection.quote(val[8]),
         ActiveRecord::Base.connection.quote(val[9]),
         ActiveRecord::Base.connection.quote(val[10]),
         ActiveRecord::Base.connection.quote(val[11]),
         ActiveRecord::Base.connection.quote(val[12])].join(', ')})"
      end.join(', ')

      ActiveRecord::Base.connection.execute("UPDATE posts AS p SET 
        views = d.views, 
        links = d.links::jsonb,
        has_photo = d.has_photo,
        has_video = d.has_video,
        next_post_at = CAST(d.next_post_at AS TIMESTAMP WITH TIME ZONE),
        html = d.html,
        is_repost = d.is_repost,
        feed_hours = d.feed_hours,
        top_hours = d.top_hours,
        last_parsed_at = CAST(d.parsed_at AS TIMESTAMP WITH TIME ZONE),
        statistic = jsonb_insert(p.statistic, '{-1}', jsonb_build_object('views', (d.views::int - COALESCE(p.views, 0)::int), 'updated_at', d.parsed_at), true)
        FROM (VALUES #{update_values}) AS 
        d(link, tg_post_id, views, links, has_photo, has_video, next_post_at, html, is_repost, channel_id, feed_hours, top_hours, parsed_at)
        WHERE p.channel_id = d.channel_id AND p.tg_id = d.tg_post_id;")

      Redis0.ltrim('update_posts_data', 0, 99999)
    end

  end
end