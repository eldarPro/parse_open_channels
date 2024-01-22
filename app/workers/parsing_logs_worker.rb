class ParsingLogsWorker
  include Sidekiq::Job
  sidekiq_options queue: :critical
  
  def perform
    active_workers_count = Sidekiq::Workers.new.size
    ParsingLog.done if active_workers_count == 0
  end
end
