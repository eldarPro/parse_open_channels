# Планировщик обновления в БД информаций о каналах
class UpdateChannelsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 0

  def perform 
    active_workers_info = Sidekiq::Workers.new.map(&:last)
    return if active_workers_info.find{ |i| i['payload']['class'] == 'UpdateChannelsWorker' } rescue nil
    
    data_count  = Redis0.llen('channels_data')
    count_batch = (data_count / 1000.to_f).ceil

    count_batch.times do
      values = Redis0.lrange('channels_data', 0, 999)

      # channel_id, subscribers, title, description, is_verify, update_info_at, parse_mode, last_post_id, last_post_date

      update_values = []
      insert_values = []

      values.each do |v| 
        val = JSON.parse(v)

        channel_id  = val[0]
        subscribers = val[1]
        title       = val[2]
        description = val[3]

        update_values << "(#{[ActiveRecord::Base.connection.quote(channel_id),
           ActiveRecord::Base.connection.quote(subscribers),
           ActiveRecord::Base.connection.quote(title),
           ActiveRecord::Base.connection.quote(description),
           ActiveRecord::Base.connection.quote(val[4]),
           ActiveRecord::Base.connection.quote(val[5]),
           ActiveRecord::Base.connection.quote((val[6] == 'by_web_parse')),
           ActiveRecord::Base.connection.quote((val[6] == 'by_telethon_parse')),
           ActiveRecord::Base.connection.quote(val[7]),
           ActiveRecord::Base.connection.quote(val[8])
         ].join(', ')})"

        insert_values << { channel_id: channel_id, subscribers: subscribers, title: title, description: description }
      end

      MainDbRecord.connection.execute("UPDATE channels AS c SET 
          subscribers = d.subscribers,
          title = d.title,
          description = d.description,
          is_verify = d.is_verify,
          update_info_at = CAST(d.update_info_at AS TIMESTAMP WITH TIME ZONE),
          by_web_parse = d.by_web_parse,
          by_telethon_parse = d.by_telethon_parse,
          last_post_id = CASE WHEN d.last_post_id IS NOT NULL THEN CAST(d.last_post_id AS INTEGER) ELSE c.last_post_id END,
          last_post_date = CASE WHEN d.last_post_date IS NOT NULL THEN CAST(d.last_post_date AS TIMESTAMP WITH TIME ZONE) ELSE c.last_post_date END
        FROM (VALUES #{update_values.join(', ')}) AS 
        d(id, subscribers, title, description, is_verify, update_info_at, by_web_parse, 
        by_telethon_parse, last_post_id, last_post_date)
        where c.id = d.id;")

      MainDb::ChannelStat.insert_all(insert_values)

      Redis0.ltrim('channels_data', 1000, -1)
    end

  end
end