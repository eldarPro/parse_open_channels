# Планировщик обновления в БД информаций о каналах
class UpdateChannelsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical_queue, retry: 0

  def perform 
    data_count = Redis0.llen('update_channels_data')
    count_batch = (data_count / 10000.0).ceil

    count_batch.times do
      values = Redis0.lrange('update_channels_data', 0, 99999)

      # channel_id, subscribers, title, description, is_verify, update_info_at, parse_mode, last_post_id, last_post_date

      update_values = values.map do |v| 
        val = JSON.parse(v)
        "(#{[ActiveRecord::Base.connection.quote(val[0]),
         ActiveRecord::Base.connection.quote(val[1]),
         ActiveRecord::Base.connection.quote(val[2]),
         ActiveRecord::Base.connection.quote(val[3]),
         ActiveRecord::Base.connection.quote(val[4]),
         ActiveRecord::Base.connection.quote(val[5]),
         ActiveRecord::Base.connection.quote((val[6] == 'by_web_parse')),
         ActiveRecord::Base.connection.quote((val[6] == 'by_telethon_parse')),
         ActiveRecord::Base.connection.quote(val[7]),
         ActiveRecord::Base.connection.quote(val[8])].join(', ')})"
      end.join(', ')

      ActiveRecord::Base.connection.execute("UPDATE channels AS c SET 
        subscribers = d.subscribers,
        title = d.title,
        description = d.description,
        is_verify = d.is_verify,
        update_info_at = CAST(d.update_info_at AS TIMESTAMP WITH TIME ZONE),
        by_web_parse = d.by_web_parse,
        by_telethon_parse = d.by_telethon_parse,
        last_post_id = d.last_post_id,
        last_post_date = CAST(d.last_post_date AS TIMESTAMP WITH TIME ZONE)
      FROM (VALUES #{update_values}) AS 
      d(id, subscribers, title, description, is_verify, update_info_at, by_web_parse, by_telethon_parse, last_post_id, last_post_date)
      where c.id = d.id;")

      insert_values = values.map do |v| 
        val = JSON.parse(v)
        "(#{[ActiveRecord::Base.connection.quote(val[0]),
         ActiveRecord::Base.connection.quote(val[1]),
         ActiveRecord::Base.connection.quote(val[2]),
         ActiveRecord::Base.connection.quote(val[3]),].join(', ')}, 
         NOW())"
      end.join(', ')

      ActiveRecord::Base.connection.execute("INSERT INTO channel_stats 
        (channel_id, subscribers, title, description, created_at) VALUES #{insert_values}")

      Redis0.ltrim('update_channels_data', 0, 99999)
    end

  end
end