# Планировщик обновления постов в БД
class UpdatePostsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 1

  def perform 
    active_workers_info = Sidekiq::Workers.new.map(&:last)
    return if active_workers_info.find{ |i| i['payload']['class'] == 'UpdatePostsWorker' } rescue nil

    # Обновление по 10к штук
    count_batch = (Redis0.llen('update_posts_data') / 1000.to_f).ceil

    count_batch.times do
      values = Redis0.lrange('update_posts_data', 0, 999)

      break unless values.present?

      values = values.map{ JSON.parse(_1) }.uniq{ _1[0] }

      # Сollection ChannelPost data
      update_values = values.map do |val| 
        "(#{[ActiveRecord::Base.connection.quote(val[1]),
         ActiveRecord::Base.connection.quote(val[2]),
         ActiveRecord::Base.connection.quote(val[4]),
         ActiveRecord::Base.connection.quote(val[5]),
         ActiveRecord::Base.connection.quote(val[7]),
         ActiveRecord::Base.connection.quote(val[9]),
         ActiveRecord::Base.connection.quote(val[10]),
         ActiveRecord::Base.connection.quote(val[11]),
         ActiveRecord::Base.connection.quote(val[12]),
         ActiveRecord::Base.connection.quote(val[13])].join(', ')})"
      end.join(', ')

      # Create ChannelPost
      posts_data = MainDbRecord.connection.execute("UPDATE channel_posts AS p SET 
        views = d.views, 
        has_photo = d.has_photo,
        has_video = d.has_video,
        next_post_at = CAST(d.next_post_at AS TIMESTAMP WITH TIME ZONE),
        is_repost = d.is_repost,
        feed_hours = d.feed_hours,
        top_hours = d.top_hours,
        last_parsed_at = d.parsed_at::timestamp - INTERVAL '3 hours',
        FROM (VALUES #{update_values}) AS 
        d(tg_id, views, has_photo, has_video, next_post_at, is_repost, channel_id, feed_hours, top_hours, parsed_at)
        WHERE p.tg_id = d.tg_id AND p.channel_id = d.channel_id RETURNING id").to_a

      create_post_stats_values = []
      create_post_infos_values = []

      posts_data.each do |i|
        # Сollection ChannelPostStat data
        create_post_stats_values << "(#{[i['id'], val[2]].join(', ')}, NOW())"
        # Сollection ChannelPostInfo data

        text  = TextFromHtml.new(val[8]).call # Берем только текст из html-кода 
        text  = ActiveRecord::Base.connection.quote(text)
        links = "#{ActiveRecord::Base.connection.quote(val[3].to_json)}"
        create_post_infos_values << "(#{[i['id'], text, links].join(', ')}, NOW())"
      end

      # Create ChannelPostStat
      ActiveRecord::Base.connection.execute("CREATE TEMPORARY TABLE temp_data (channel_post_id INTEGER, views INTEGER, created_at TIMESTAMP)")
      ActiveRecord::Base.connection.execute("INSERT INTO temp_data (channel_post_id, views, created_at) VALUES #{create_post_stats_values.join(', ')}")
      res = ActiveRecord::Base.connection.execute("INSERT INTO channel_post_stats (channel_post_id, views, created_at)
        SELECT td.channel_post_id, td.views, td.created_at
        FROM temp_data AS td
        LEFT JOIN channel_post_stats ps ON td.channel_post_id = ps.channel_post_id AND td.views = ps.views
        WHERE ps.channel_post_id IS NULL")
        ActiveRecord::Base.connection.execute("DROP TABLE temp_data")

      # Create ChannelPostInfo
      ActiveRecord::Base.connection.execute("CREATE TEMPORARY TABLE temp_data (channel_post_id INTEGER, text TEXT, links TEXT[], created_at TIMESTAMP)")
      ActiveRecord::Base.connection.execute("INSERT INTO temp_data (channel_post_id, text, links, created_at) VALUES #{create_post_infos_values.join(', ')}")
      res = ActiveRecord::Base.connection.execute("INSERT INTO channel_post_infos (channel_post_id, text, links, created_at)
        SELECT td.channel_post_id, td.text, td.links, td.created_at
        FROM temp_data AS td
        LEFT JOIN channel_post_infos ps ON td.channel_post_id = ps.channel_post_id AND td.text = ps.text AND td.links = ps.links
        WHERE ps.channel_post_id IS NULL")
        ActiveRecord::Base.connection.execute("DROP TABLE temp_data")

      Redis0.ltrim('update_posts_data', 1000, -1)
    end

  end
end
