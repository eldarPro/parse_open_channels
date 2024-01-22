class ChannelIsVerified

  attr_accessor :doc

  def initialize(doc)
    @doc = doc
  end

  def call
    return if doc.blank?
    html_with_verify_icon = doc&.css('.verified-icon')
    html_with_verify_icon.present?
  end

end