# Планировщик обновления в БД информаций о каналах
class UpdateChannelsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 1

  def perform 
    return if ActiveWorkers.new(self.class.to_s).is_active?

    data_count  = Redis0.llen('channels_data')
    count_batch = (data_count / 1000.to_f).ceil

    count_batch.times do
      values = Redis0.lrange('channels_data', 0, 999)

      # channel_id, subscribers, title, description, is_verify, update_info_at, by_telethon_parse, last_post_id, last_post_date

      update_values = []
      insert_values = []

      values.each do |v| 
        val = JSON.parse(v)

        channel_id        = val[0]
        subscribers       = val[1]
        title             = val[2]
        description       = val[3]
        by_telethon_parse = val[6]

        last_channel_data = Redis0.get("last_channel_data:#{channel_id}")
        last_channel_data = JSON.parse(last_channel_data) if last_channel_data.present?

        if channel_data_changed?(last_channel_data, subscribers, title, description, by_telethon_parse)
          update_values << "(#{[ActiveRecord::Base.connection.quote(channel_id),
             ActiveRecord::Base.connection.quote(subscribers),
             ActiveRecord::Base.connection.quote(title),
             ActiveRecord::Base.connection.quote(description),
             ActiveRecord::Base.connection.quote(val[4]),
             ActiveRecord::Base.connection.quote(val[5]),
             ActiveRecord::Base.connection.quote(by_telethon_parse),
             ActiveRecord::Base.connection.quote(val[7]),
             ActiveRecord::Base.connection.quote(val[8])
           ].join(', ')})"

           Redis0.set("last_channel_data:#{channel_id}", [subscribers, title, description, by_telethon_parse].to_json)
         end

        if channel_stat_data_changed?(last_channel_data, subscribers, title, description)
          insert_values << { channel_id: channel_id, subscribers: subscribers, title: title, description: description }
        end
      end

      if update_values.present?
        MainDbRecord.connection.execute("UPDATE channels AS c SET 
            subscribers = d.subscribers,
            title = d.title,
            description = d.description,
            is_verify = d.is_verify,
            update_info_at = CAST(d.update_info_at AS TIMESTAMP WITH TIME ZONE),
            by_telethon_parse = d.by_telethon_parse,
            last_post_id = CASE WHEN d.last_post_id IS NOT NULL THEN CAST(d.last_post_id AS INTEGER) ELSE c.last_post_id END,
            last_post_date = CASE WHEN d.last_post_date IS NOT NULL THEN CAST(d.last_post_date AS TIMESTAMP WITH TIME ZONE) ELSE c.last_post_date END
          FROM (VALUES #{update_values.join(', ')}) AS 
          d(id, subscribers, title, description, is_verify, update_info_at, 
          by_telethon_parse, last_post_id, last_post_date)
          where c.id = d.id;")
      end

      MainDb::ChannelStat.insert_all(insert_values) if insert_values.present?

      Redis0.ltrim('channels_data', 1000, -1)
    end
  end

  private

  def channel_data_changed?(data, subscribers, title, description, by_telethon_parse)
    return true if data.blank? 
    return true if data[0] != subscribers
    return true if data[1] != title
    return true if data[2] != description
    return true if data[3] != by_telethon_parse
    false
  end

  def channel_stat_data_changed?(data, subscribers, title, description)
    return true if data.blank? 
    return true if data[0] != subscribers
    return true if data[1] != title
    return true if data[2] != description
    false
  end
end