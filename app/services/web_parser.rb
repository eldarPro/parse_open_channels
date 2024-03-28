class WebParser

  attr_accessor :channel_id
  attr_accessor :channel_name
  attr_accessor :before_post_id
  attr_accessor :first_page_parse
  attr_accessor :post_views_key
  attr_accessor :count_posts

  CHANGE_STRUCT = 'change_struct'

  def initialize(channel_id, channel_name, before_post_id = nil, count_posts = 0)
    @channel_id       = channel_id
    @channel_name     = channel_name
    @before_post_id   = before_post_id
    @first_page_parse = before_post_id.nil?
    @post_views_key   = "post_views:#{channel_id}:#{Time.now.strftime('%d_%H')}"
    @count_posts      = count_posts
  end

  def parse
    return if channel_id.blank? || channel_name.blank?

    # Если это парсинг первой страницы постов, то парсит параллельно посты и канал, иначе только посты
    if first_page_parse
      thread1 = Thread.new { parse_posts(before_post_id) }
      thread2 = Thread.new { parse_channels }

      thread1.join
      thread2.join

      result_parse_posts = thread1.value
      posts              = result_parse_posts[0] rescue []
      by_telethon_parse  = result_parse_posts[1] rescue false
      
      channels = thread2.value
    else
      posts    = parse_posts(before_post_id)[0] rescue []
      channels = []
    end

    if posts.present? 
      # Если изменилась структура скелета, то бьет тревогу
      SendAlertMessage.new(:change_post_struct).call and return if posts == CHANGE_STRUCT
      
      present_old_7day_post = false
      posts.each do |post_data| 
        present_old_7day_post = true and next if post_data[6] < 7.days.ago # published_at < 7.days.ago
        #Redis0.rpush('posts_data', post_data.to_json)
      end
      current_count_posts = count_posts + posts.length
      return if present_old_7day_post     # Остановка если уже есть пост страше 7-дней
      return if current_count_posts >= 70 # Остановка если уже набралась 70 постов
      ParseChannelWorker.perform_async(channel_id, channel_name, posts.first[1], current_count_posts) 
    end

    #========= КАНАЛЫ ===============
    return if !first_page_parse || channels.blank?

    last_post_date = posts.last[6] rescue nil

    channels << by_telethon_parse
    channels << last_post_date
    Redis0.rpush('channels_data', channels.to_json)
  end

  private

  def parse_posts(before_post_id)
    url = "https://t.me/s/#{channel_name}?before=#{before_post_id}"
    doc = SendRequest.new(url).call

    if doc == :failed
      Redis0.rpush('failed_channels', channel_name)
      return nil 
    end

    by_telethon_parse = true
    posts = []

    if doc&.css(".tgme_widget_message").present?
      by_telethon_parse = false
      doc.css(".tgme_widget_message").each.with_index do |post_html, inx|
        post_id = post_html.attr('data-post')&.split('/')&.last&.to_i
        next if post_id.nil? || post_id == 1 # Если id отсутствует или это первый пост (дата добавления), то пропускает
        next if post_html.css(".service_message")&.count > 0 # Есть такой, пока не понятно для чего
        # Если нет блока просмотров, то скорее всего это закреление, и не добавляет в список
        next if post_html.css(".tgme_widget_message_views").blank?
        post_data = GetPostDataFromHtml.new(post_html, doc).call
        posts = CHANGE_STRUCT and break if post_data == CHANGE_STRUCT # Если изменилась структура скелета
        add_other_data_to_post_data(post_data) # Добавление данных не из парсинга 
        posts << post_data
      end
    end

    [posts, by_telethon_parse]
  end

  def parse_channels
    link = "https://t.me/#{channel_name}"

    doc = SendRequest.new(link, proxy: true).call

    if doc == :failed
      Redis0.rpush('failed_channels', channel_name)
      return nil 
    end

    if doc&.css('.tgme_page_extra')&.blank?
      Redis0.rpush('empty_channels', channel_name)
      return nil 
    end
      
    subscribers    = doc.css('.tgme_page_extra').text.gsub(' ', '').to_i
    title          = doc.css(".tgme_page .tgme_page_title span").text
    description    = doc.css(".tgme_page .tgme_page_description").text
    is_verify      = doc.css('.verified-icon').present?
    #avatar_url     = doc.css('.tgme_page_photo_image')&.attr('src')&.value
    update_info_at = Time.now

    #if avatar_url.present? && (channel.avatar_updated_at.nil? || channel.avatar_updated_at < 7.days.ago)
    #  channel.avatar.attach(io: URI.parse(avatar_url).open, filename: "avatar-#{channel_id}.jpg")
    #  channel.avatar_updated_at = Time.now
    #end

    [channel_id, subscribers, title, description, is_verify, update_info_at]
  end

  def add_other_data_to_post_data(post_data)
    post_data << channel_id

    feed_hours = (Time.now - post_data[6].to_time) / 1.hour # Time.now - published_at

    if post_data[7].blank? # next_post_at.blank?
      top_hours = feed_hours
    else
      top_hours = (post_data[7].to_time - post_data[6].to_time) / 1.hour # next_post_at - published_at
    end

    post_data << feed_hours
    post_data << top_hours
    post_data << Time.now.strftime('%d.%m.%Y %H:%M:%S')
    post_data 
  end

end
