class WebParser

  attr_accessor :channel_id
  attr_accessor :channel_name
  attr_accessor :before_post_id
  attr_accessor :parse_mode
  attr_accessor :first_page_parse
  attr_accessor :info
  attr_accessor :last_post_id
  attr_accessor :new_last_post_id
  attr_accessor :last_post_date

  CHANGE_STRUCT = 'change_struct'

  def initialize(channel_id, channel_name, last_post_id, before_post_id = nil)
    @channel_id       = channel_id
    @channel_name     = channel_name
    @before_post_id   = before_post_id
    @first_page_parse = before_post_id.nil?
    @last_post_id     = last_post_id
    @new_last_post_id = last_post_id
    @last_post_date   = last_post_date
    @parse_mode       = :by_web_parse
  end

  def parse
    return if channel_name.blank?

    # Если это парсинг первой страницы постов, то парсит параллельно посты и канал, иначе только посты
    if first_page_parse
      thread1 = Thread.new { parse_channel_posts }
      thread2 = Thread.new { update_channel_info }

      thread1.join
      thread2.join

      channel_info_data = thread2.value << parse_mode rescue nil
      channel_info_data << new_last_post_id
      channel_info_data << last_post_date
      Redis0.rpush('update_channels_data', channel_info_data.to_json) if channel_info_data.present?
    else
      parse_channel_posts
    end
  end

  private

  def parse_channel_posts
    part_posts = get_posts(before_post_id)
    return if part_posts.blank? 

    # Если изменилась структура скелета, то бьет тревогу
    if part_posts == CHANGE_STRUCT
      SendAlertMessage.new('Изменилась структура постов парсинга').call 
      return
    end

    # Забирает нужные данные из поста для обновления канала
    if first_page_parse
      new_last_post_id = part_posts.last[1] 
      last_post_date   = part_posts.last[6]
    end
    
    before_post_id = part_posts.first[1]

    present_old_7day_post = false

    part_posts.each do |post_data| 
      present_old_7day_post = true and next if post_data[6] < 7.days.ago # published_at < 7.days.ago

      # Определяет в какой хранилище добавить данные: для обновления или добавления постов
      if last_post_id.present? && last_post_id >= post_data[1]
        remove_data_for_update_post(post_data) # Удаляет ненужные данные для обновления
        Redis0.rpush('update_posts_data', post_data.to_json)
      else
        Redis0.rpush('create_posts_data', post_data.to_json)
      end
    end

    return if present_old_7day_post # Если есть пост, который старше 7 дней, то прекращает запросы
    
    # А если еще нет поста страше 7-ми дней, то идет парсинг следующей страницы
    # с подачей номера поста от которого надо исходить, чтобы найти предыдущие посты
    ParseChannelWorker.perform_async(channel_id, channel_name, last_post_id, before_post_id)
  end

  def update_channel_info
    link = "https://t.me/#{channel_name}"

    doc = SendRequest.new(link, proxy: true).call

    return nil if doc&.css('.tgme_page .tgme_page_extra')&.blank?
      
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

  def get_posts(before_post_id)
    url = "https://t.me/s/#{channel_name}?before=#{before_post_id}"
    doc = SendRequest.new(url).call
    
    # Если блок tgme_widget_message отсутсвует, значит = by_telethon_parse,
    # то есть, канал закрытый, поэтому прекращает дальнейший парсинг
    # Проверку делает только один раз при парсинге первой страницы
    if first_page_parse && doc&.css(".tgme_widget_message").blank?
      parse_mode = :by_telethon_parse 
      return nil
    end
    
    res = []

    return res if doc&.css(".tgme_widget_message").blank?

    doc.css(".tgme_widget_message").each.with_index do |post_html, inx|
      post_id = post_html.attr('data-post')&.split('/')&.last&.to_i
      next if post_id.nil? || post_id == 1 # Если id отсутствует или это первый пост (дата добавления), то пропускает
      next if post_html.css(".service_message")&.count > 0 # Есть такой, пока не понятно для чего
      # Если нет блока просмотров, то скорее всего это закреление, и не добавляет в список
      next if post_html.css(".tgme_widget_message_views").blank?
      post_data = GetPostDataFromHtml.new(post_html, doc).call
      res = CHANGE_STRUCT and break if post_data == CHANGE_STRUCT # Если изменилась структура скелета
      add_other_data_to_post_data(post_data) # Добавление данных не из парсинга 
      res << post_data
    end

    res
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
    post_data << Time.now
    post_data 
  end

  def remove_data_for_update_post(post_data)
    post_data.delete_at(6) # delete published_at
  end

end
