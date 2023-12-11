# re-name for server WebParser::Base
class WebParser::Base
  def initialize(channel:)
    @channel = channel
  end

  def parsing_mode_define
    channel_name = @channel.names.first_available
    url = "https://t.me/s/#{channel_name}/10000000"
    p url
    doc = send_request(url: url)
    post_id = doc&.css('.tgme_widget_message')&.first&.attr('data-post')&.split('/')&.last&.to_i
    is_web_parse = post_id.present?
    is_web_parse ? :by_web_parse : :by_telethon_parse
  end

  def update_channel_info
    begin
      # log = log_id.present? ? BufferedLogger.new(log_id, key: log_id) : nil
      # if link include joinchat and we will try all joinchat
      joinchats_attempt ||= 0
      is_try_by_name ||= true
      # p "start script with joinchats_attempt #{joinchats_attempt}, tg_id: #{@channel.tg_id}"
      max_attempt_joinchat = @channel.joinchats.count

      link = if @channel.link == 'https://t.me/' && @channel.joinchat.present?
               p "first condition joinchats_attempt #{joinchats_attempt}"
               "#{@channel.link}#{@channel.joinchat}"
             elsif joinchats_attempt > 0 && is_try_by_name
               p "start condition try by name"
               is_try_by_name = false
               "https://t.me/#{@channel.name}"
             elsif joinchats_attempt > 0
               p "get link joinchats_attempt #{joinchats_attempt}"
               "https://t.me/#{@channel.joinchats[joinchats_attempt][0]}"
             else
               p "else condition joinchats_attempt #{joinchats_attempt}"
               @channel.link
             end

      doc = send_request(url: link)
      if doc&.css(".tgme_page .tgme_page_extra")&.blank?
        # we will imagine that the first link has already gone
        if @channel.joinchats.count > 1 && joinchats_attempt < max_attempt_joinchat
          raise StandardError.new('TryAnotherJoinchat')
        else
          # try last scenario if no data from link
          link = "https://t.me/+#{@channel.name}"
          doc = send_request(url: link)
          if doc&.css('.tgme_page .tgme_page_extra')&.blank?
            @channel.update_column(:is_empty, true)
            return nil
          end
        end
      end

      web_data = {}
      text_with_members_count = doc.css('.tgme_page_extra')&.text
      # if text_with_members_count not include members then broadcast = false
      web_data[:broadcast] = !text_with_members_count.include?('members')
      web_data[:subscribers] = text_with_members_count.gsub(' ', '').to_i
      web_data[:title] = doc.css(".tgme_page .tgme_page_title span").text
      web_data[:description] = doc.css(".tgme_page .tgme_page_description").text
      web_data[:is_verify] = Channel.verified?(doc)
      web_data[:avatar_url] = doc.css('.tgme_page_photo_image')&.attr('src')&.value

      if web_data[:avatar_url].present? && (@channel.avatar_updated_at.nil? || @channel.avatar_updated_at < 7.days.ago)
        @channel.avatar.attach(io: URI.parse(web_data[:avatar_url]).open, filename: "avatar-#{@channel.id}.jpg")
        @channel.avatar_updated_at = Time.now
      end
      # Rails.application.routes.url_helpers.rails_blob_path(channel.avatar, only_path: true)

      @channel.subscribers = web_data[:subscribers]
      @channel.title = web_data[:title]
      @channel.description = web_data[:description]
      @channel.broadcast = web_data[:broadcast]
      @channel.is_verify = web_data[:is_verify]
      @channel.avatar_url = web_data[:avatar_url]
      @channel.is_empty = false
      # p "web_data = #{web_data}"
      # log.push("web_data = #{web_data}") if log.present?
      @channel.update_info_at = Time.now

      if @channel.save
        p "channel is save"
        # log.push("channel #{@channel.id} is save") if log.present?

        # if channel save, we need to save history statistics
        statistic_params = {
          subscribers: @channel.subscribers,
          title: @channel.title,
          description: @channel.description
        }
        # TODO: need new data for diffrent attribute
        statistic = ChannelStat.where(channel_id: @channel.id).where('created_at > ?', 12.hours.ago).first
        if statistic.present?
          statistic.update! statistic_params
        else
          # TODO: need new data for diffrent attribute
          channel_average_views = @channel.calc_average_views
          @channel.update_column(:average_views, channel_average_views)
          statistic_params.merge!({ average_views: channel_average_views })
          ChannelStat.create!(statistic_params.merge({ channel: @channel }))
        end
        return @channel
      else
        p "channel not save"
        # log.push("channel #{@channel.id} channel not save") if log.present?
        p "e #{@channel.errors.messages.inspect}" if @channel.errors.present?
        # log.push("e #{@channel.errors.messages.inspect}") if (log.present? && @channel.errors.present?)
        # p "channel tg id is #{channel.tg_id}"
        nil
      end
    rescue => e
      if e.message == "TryAnotherJoinchat"
        joinchats_attempt += 1
        p "TryAnotherJoinchat"
        retry
      end
    end
  end

  def get_last_posts
    data = nil
    result = 0
    log_id = "get_last_post-#{rand(0..100_000)}"
    log = BufferedLogger.new(log_id, key: log_id)
    name = @channel.names.first_available

    if @channel.last_post_id.blank? || @channel.last_post_date&.<(7.days.ago)
      data = get_posts(channel_name: name, tg_id: 10000000)
      if data.present? && data[:data].count > 0
        tg_id = data[:data].last[:id]-100
        tg_id = @channel.last_post_date&.<(7.days.ago) ? [tg_id, @channel.last_post_id.to_i + 1].max : tg_id
        data = get_posts(channel_name: name, tg_id: tg_id)
      end
    else
      data = get_posts(channel_name: name, tg_id: @channel.last_post_id)
    end
    # data

    if data&.[](:data).present?
      data[:data].sort_by { |message| message[:id] }.each do |message|
        if @channel.last_post_id.blank? || message[:id] > @channel.last_post_id
          post = Post.create(channel: @channel,
                             link: "https://t.me/#{@channel.post_link_id}/#{message[:id]}",
                             skip_screen: true)
          result +=1 if post.store_parsed_data_to_db(message, log)
        end
      end
      # RedisCounters.inc("channels_get_last_posts_speed_#{group}")
    end
    @channel.touch :get_last_posts_at
    # log.push "stored to db #{result} posts".green
    # log.break_line
    result
  end

  def get_posts(channel_name:, tg_id:)
    url_neighboring_posts = "https://t.me/s/#{channel_name}/#{tg_id+10}"
    main_post_url = "https://t.me/#{channel_name}/#{tg_id}?embed=1&mode=tme"

    web_data = { data: [] }
    web_data[:data] += send_request_and_get_posts_data(url: url_neighboring_posts)

    # if tg_id == 10000000 we not found the post and must skip this method
    web_data[:data] += send_request_and_get_posts_data(url: main_post_url) if tg_id != 10000000
    web_data
  end

  def send_request_and_get_posts_data(url:)
    data = []
    doc = send_request(url: url)
    doc&.css(".tgme_widget_message")&.each do |post_html|
      post_data = GetPostDataFromHtml.new(post_html, doc).call
      data << post_data if post_data.present?
    end
    data
  end

  def send_request(url:)
    http, _proxy = Proxy.http url, type: :https
    response = http.get(url)
    return unless response.is_a? Net::HTTPSuccess

    Nokogiri::HTML.parse(response.body)
  end
end