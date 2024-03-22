# Планировщик парсинга каналов
class SchedulerParseChannelWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 0

  def perform
    parse_count = MainDb::Channel.opens.active.count

    ParsingLog.start(parse_count)

    MainDb::Channel.select(:id, :name).opens.active.find_each(batch_size: 10_000) do |channel|
      ParseChannelWorker.perform_async(channel.id, channel.name)
    end
  end
end