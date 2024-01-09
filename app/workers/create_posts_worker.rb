# Планировщик добавления постов в БД
class SchedulerCreatePostsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :job_scheduler_queue, retry: 0

  def perform 
    count_batch = (Redis0.llen('create_posts_data') / 10000.0).ceil

    count_batch.times do
      values = Redis0.lrange('create_posts_data', 0, 99999)

      insert_values = values.map do |v| 
        val = JSON.parse(v)
        "(#{[ActiveRecord::Base.connection.quote(val[0]),
         ActiveRecord::Base.connection.quote(val[1]),
         ActiveRecord::Base.connection.quote(val[2]),
         "#{ActiveRecord::Base.connection.quote(val[3].to_json)}",
         "#{ActiveRecord::Base.connection.quote([{views: val[2], updated_at: val[-1]}].to_json)}",
         ActiveRecord::Base.connection.quote(val[4]),
         ActiveRecord::Base.connection.quote(val[5]),
         ActiveRecord::Base.connection.quote(val[6]),
         ActiveRecord::Base.connection.quote(val[7]),
         ActiveRecord::Base.connection.quote(val[8]),
         ActiveRecord::Base.connection.quote(val[9]),
         ActiveRecord::Base.connection.quote(val[10]),
         ActiveRecord::Base.connection.quote('true'),
         ActiveRecord::Base.connection.quote(val[11]),
         ActiveRecord::Base.connection.quote(val[12]),
         ActiveRecord::Base.connection.quote(val[13])].join(', ')}, 
         NOW(),
         NOW())"
      end.join(', ')

      ActiveRecord::Base.connection.execute("INSERT INTO posts 
        (link, tg_id, views, links, statistic, has_photo, has_video, published_at, next_post_at, html, is_repost, channel_id, skip_screen, feed_hours, top_hours, last_parsed_at, created_at, updated_at)
        VALUES #{insert_values}") # ON CONFLICT (link) DO NOTHING; - добавить внутри когда будет уникальный индекс по link

      Redis0.ltrim('create_posts_data', 0, 99999)
    end

  end
end

