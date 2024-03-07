# Планировщик обновления постов в БД
class CreatePostsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 1

  def perform 
    active_workers_info = Sidekiq::Workers.new.map(&:last)
    return if active_workers_info.find{ |i| JSON.parse(i['payload'])['class'] == 'CreatePostsWorker' }.present? rescue nil

    # Обновление по 10к штук
    count_batch = (Redis0.llen('create_posts_data') / 1000.to_f).ceil

    count_batch.times do
      values = Redis0.lrange('create_posts_data', 0, 999)

      break unless values.present?

      values = values.map{ JSON.parse(_1) }.uniq{ _1[0] }

      # Сollection ChannelPost data
      create_posts_values = values.map do |val| 
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

      # Create ChannelPost
      posts_data = MainDbRecord.connection.execute("INSERT INTO channel_posts
        (link, tg_id, views, has_photo, has_video, published_at, next_post_at, is_repost, channel_id, feed_hours, top_hours, last_parsed_at, created_at, updated_at)
        VALUES #{create_posts_values} ON CONFLICT DO NOTHING RETURNING id").to_a

      create_post_stats_values = []
      create_post_infos_values = []

      posts_data.each do |i|
        # Сollection ChannelPostStat data
        create_post_stats_values << { channel_post_id: i['id'], views: val[2] } 
        # Сollection ChannelPostInfo data
        text = TextFromHtml.new(val[8]).call # Берем только текст из html-кода 
        create_post_infos_values << { channel_post_id: i['id'], text: text, links: val[3] }
      end

      MainDb::ChannelPostStat.insert_all(create_post_stats_values) # Create ChannelPostStat
      MainDb::ChannelPostInfo.insert_all(create_post_infos_values) # Create ChannelPostInfo

      Redis0.ltrim('create_posts_data', 1000, -1)
    end

  end
end