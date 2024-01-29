# Планировщик парсинга каналов
class SchedulerParseChannelWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 0

  def perform

    parse_count = Channel.select(:id, :name).count

    ParsingLog.start(parse_count)

    Channel.select(:id, :name).all.find_each(batch_size: 10_000) do |channel|
      ParseChannelWorker.perform_async(channel.id, channel.name)
    end
  end
end