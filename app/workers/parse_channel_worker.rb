# Парсинг канала
class ParseChannelWorker
  include Sidekiq::Job
  
  def perform(channel_id, channel_name, last_post_id, before_post_id = nil)
    WebParser.new(channel_id, channel_name, last_post_id, before_post_id).parse
  end
end