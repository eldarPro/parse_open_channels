# Планировщик добавления/обновления постов в БД
class UpsertPostsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 0

  def perform
    return if ActiveWorkers.new(self.class.to_s).is_active?

    # Обновление по 1000 штук
    count_batch = (Redis0.llen('posts_data') / 1000.to_f).ceil

    count_batch.times do
      data_values = Redis0.lrange('posts_data', 0, 999)

      break unless data_values.present?

      # Сборка ChannelPost
      posts_values = data_values.map do |val| 
        val = JSON.parse(_1)
        "(#{[ActiveRecord::Base.connection.quote(val[0]),
         ActiveRecord::Base.connection.quote(val[1]),
         ActiveRecord::Base.connection.quote(val[2]),
         ActiveRecord::Base.connection.quote(val[4]),
         ActiveRecord::Base.connection.quote(val[5]),
         ActiveRecord::Base.connection.quote(val[6]),
         ActiveRecord::Base.connection.quote(val[7]),
         ActiveRecord::Base.connection.quote(val[9]),
         ActiveRecord::Base.connection.quote(val[10]),
         ActiveRecord::Base.connection.quote(val[11]),
         ActiveRecord::Base.connection.quote(val[12]),
         ActiveRecord::Base.connection.quote(val[13]),
         ActiveRecord::Base.connection.quote(Time.parse(val[14]))].join(', ')}, 
         NOW(),
         NOW())"
      end.join(', ')

      # Создание ChannelPost
      posts_data = MainDbRecord.connection.execute("INSERT INTO channel_posts AS p
        (link, tg_id, views, has_photo, has_video, published_at, next_post_at, is_repost, channel_id, feed_hours, top_hours, last_parsed_at, created_at, updated_at)
        VALUES #{posts_values} ON CONFLICT (link) DO UPDATE SET 
        views = EXCLUDED.views, 
        has_photo = EXCLUDED.has_photo,
        has_video = EXCLUDED.has_video,
        next_post_at = CAST(EXCLUDED.next_post_at AS TIMESTAMP WITH TIME ZONE),
        is_repost = EXCLUDED.is_repost,
        feed_hours = EXCLUDED.feed_hours,
        top_hours = EXCLUDED.top_hours,
        last_parsed_at = CAST(EXCLUDED.last_parsed_at AS TIMESTAMP WITH TIME ZONE),
        updated_at = NOW() 
        RETURNING id, tg_id, channel_id")

      create_post_stats_values = []
      create_post_infos_values = []

      data_values.each do |val|
        channel_post_id = posts_data.as_json.find{ _1['tg_id'] == val[:tg_id] && _1['channel_id'] == val[:channel_id] }['id'] rescue nil
        next if channel_post_id.blank?

        # Сборка ChannelPostStat
        create_post_stats_values << "(#{[channel_post_id, ActiveRecord::Base.connection.quote(val[2])].join(', ')}, NOW())" 
        # Сборка ChannelPostInfo
        create_post_infos_values << "(#{[channel_post_id, ActiveRecord::Base.connection.quote(val[8]), val[8].length,
                                         ActiveRecord::Base.connection.quote(val[3].to_json)].join(', ')}, NOW())" 
      end

      # Создание ChannelPostStat
      MainDbRecord.connection.execute("INSERT INTO channel_post_stats (channel_post_id, views, created_at) 
        VALUES #{create_post_stats_values.join(', ')} ON CONFLICT (channel_post_id, views) DO NOTHING;") if create_post_stats_values.present?
      
      # Создание ChannelPostInfo
      MainDbRecord.connection.execute("INSERT INTO channel_post_infos (channel_post_id, text, text_length, links, created_at) 
        VALUES #{create_post_infos_values.join(', ')} ON CONFLICT (channel_post_id, text_length) DO NOTHING;") if create_post_infos_values.present?
    
      Redis0.ltrim('posts_data', 1000, -1)
    end
  end
end 
