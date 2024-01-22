# Парсинг канала
class TestWorker
  include Sidekiq::Job
  sidekiq_options queue: :default
  
  def perform
    sleep 120
  end
end
