class SendRequest

  attr_accessor :url
  attr_accessor :proxy

  def initialize(url, proxy: false)
    @url   = url
    @proxy = proxy
  end

  def call
    http = MainDb::Proxy.http(url, proxy_enable: proxy, type: :https)
    response = http.get(url)
    return unless response.is_a? Net::HTTPSuccess
    Nokogiri::HTML.parse(response.body)
  end

end