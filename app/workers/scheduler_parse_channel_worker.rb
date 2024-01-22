# Планировщик парсинга каналов
class SchedulerParseChannelWorker
  include Sidekiq::Worker
  sidekiq_options queue: :job_scheduler, retry: 0

  def perform

    parse_count = Channel.select(:id, :name).limit(70_000).count

    ParsingLog.start(parse_count)

    Channel.select(:id, :name).limit(70_000).find_each(batch_size: 10_000) do |channel|
      ParseChannelWorker.perform_async(channel.id, channel.name)
    end
  end
end