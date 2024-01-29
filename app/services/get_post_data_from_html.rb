class GetPostDataFromHtml
  attr_accessor :post_html
  attr_accessor :doc

  def initialize(post_html, doc)
    @post_html = post_html
    @doc       = doc
  end

  def call
    link = post_html.attr('data-post')
    return WebParser::CHANGE_STRUCT if link.nil?

    tg_post_id = link.split('/').last.to_i
  
    views = post_html.css(".tgme_widget_message_views").text.gsub('K','00').gsub('.','').to_i rescue nil
    return WebParser::CHANGE_STRUCT if views.nil?    
    
    links = post_html.css(".js-message_text a").map{_1.attr('href')}.uniq rescue nil
    return WebParser::CHANGE_STRUCT if links.nil?
    
    has_photo = post_html.css(".tgme_widget_message_photo_wrap").present?
    has_video = post_html.css(".message_video_play").present?

    published_at = post_html.css(".tgme_widget_message_date time").attr('datetime').value.to_datetime rescue nil
    return WebParser::CHANGE_STRUCT if published_at.blank?

    next_post_at = get_next_post_at(tg_post_id)
    html         = post_html.css(".js-message_text").to_html
    is_repost    = post_html.css(".tgme_widget_message_forwarded_from").present?
    
    [link, tg_post_id, views, links, has_photo, has_video, published_at, next_post_at, html, is_repost]
  end

  private

  def get_next_post_at(tg_post_id)
    doc.css(".tgme_widget_message").to_a.
      find{ _1.attr('data-post').split('/').last.to_i > tg_post_id }.
      search('.tgme_widget_message_date time').first.attr('datetime').to_datetime rescue nil
  end

end
