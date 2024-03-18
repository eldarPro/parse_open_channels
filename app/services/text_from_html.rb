class TextFromHtml

  attr_accessor :html

  def initialize(html)
    @html = html
  end

  def call
    Nokogiri::HTML(html).text rescue html
  end

end