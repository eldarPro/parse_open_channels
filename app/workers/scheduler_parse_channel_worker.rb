# Планировщик парсинга каналов
class SchedulerParseChannelWorker
  include Sidekiq::Worker
  sidekiq_options queue: :job_scheduler, retry: 0

  def perform
    return unless Rails.env.production?

    #MainDb::Channel.select(:id, :name).where(new_tg_id: nil, main_channel_id: nil, by_web_parse: [true, nil]).limit(10000).find_each do |channel|
    #Channel.select(:id, :name).find_each(batch_size: 10_000) do |channel|
    #  ParseChannelWorker.perform_async(channel.id, channel.name)
    #end
  end
end