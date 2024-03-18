class LinkCheckWorker
  include Sidekiq::Job
  sidekiq_options queue: :default
  
  def perform(fr_id, link)
    link = "https://t.me/#{link}"
    doc = SendRequest.new(link, proxy: true).call
    return if doc&.css('.tgme_page_extra')&.present?
    Redis0.rpush('empty_link_ids', fr_id)
  end
end