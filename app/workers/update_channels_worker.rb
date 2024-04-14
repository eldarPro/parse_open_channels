# Планировщик обновления в БД информаций о каналах
class UpdateChannelsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 1

  def perform 
    return if ActiveWorkers.new(self).is_active?

    data_count    = Redis0.llen('channels_data')
    count_batch   = (data_count / 1000.to_f).ceil
    model_columns = MainDb::Channel.columns
    columns       = [:id, :subscribers, :title, :description, :is_verify, :update_info_at, :by_telethon_parse, :last_post_date]

    count_batch.times do
      values = Redis0.lrange('channels_data', 0, 999)

      update_values = []
      insert_values = []
      channel_ids   = []

      values.each do |v| 
        val = JSON.parse(v)
        channel_ids << val[0]
        update_values << "(#{columns.map.with_index do |col, inx|
          find_column = model_columns.find{ _1.name == col.to_s }
          ActiveRecord::Base.connection.quote_default_expression(val[inx], find_column)
        end.join(', ')})"
        insert_values << { channel_id: val[0], subscribers: val[1], title: val[2], description: val[3] }
      end

      if update_values.present?
        insert_values = delete_in_non_changes(channel_ids, insert_values)
        update_channels(update_values)        
        MainDb::ChannelStat.insert_all(insert_values) if insert_values.present?
      end

      Redis0.ltrim('channels_data', 1000, -1)
    end
  end

  private

  def update_channels(data)
    MainDbRecord.connection.execute("UPDATE channels AS c SET 
      subscribers = d.subscribers,
      title = d.title,
      description = d.description,
      is_verify = d.is_verify,
      update_info_at = d.update_info_at,
      by_telethon_parse = d.by_telethon_parse,
      last_post_date = CASE WHEN d.last_post_date IS NOT NULL THEN CAST(d.last_post_date AS TIMESTAMP WITH TIME ZONE) ELSE c.last_post_date END
    FROM (VALUES #{data.join(', ')}) AS 
    d(id, subscribers, title, description, is_verify, update_info_at, by_telethon_parse, last_post_date)
    WHERE c.id = d.id;")
  end

  # Удаляет позиции, которые не изменилсь
  def delete_in_non_changes(channel_ids, values)
    channels = MainDb::Channel.select(:id, :subscribers, :title, :description).where(id: channel_ids)
    values.delete_if do |i| 
      channel = channels.find{ |c| c.id == i[:channel_id] }
      return true if channel.blank?
      channel.subscribers == i[:subscribers] && channel.title == i[:title] && channel.description == i[:description]
    end
  end
end