# Парсинг канала
class ParseChannelWorker
  include Sidekiq::Job
  sidekiq_options queue: :default
  
  def perform(channel_id, channel_name, last_post_id, before_post_id = nil, count_posts = 0)
    WebParser.new(channel_id, channel_name, last_post_id, before_post_id, count_posts).parse
  end
end
