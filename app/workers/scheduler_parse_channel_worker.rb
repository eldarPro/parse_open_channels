# Планировщик парсинга каналов
class SchedulerParseChannelWorker
  include Sidekiq::Worker
  sidekiq_options queue: :job_scheduler_queue, retry: 0

  def perform
    return unless Rails.env.production?

    Channel.select(:id, :name, :last_post_id).where(new_tg_id: nil, main_channel_id: nil, by_web_parse: [true, nil]).limit(10000).find_each do |channel|
      ParseChannelWorker.perform_async(channel.id, channel.name, channel.last_post_id)
    end
  end
end

channel = Channel.find(750387)
ParseChannelWorker.new.perform(channel.id, channel.name, channel.last_post_id)