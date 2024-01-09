class TelegramLink < String
  def self.parse(x)
    x&.strip!
    original = x
    self.new x.match(/([c]\/\d+|[a-zA-z_0-9]+)\/\d+\z/)[0]
  rescue
    self.new original
  end

  def canonical
    "https://t.me/#{self}" if self.present?
  end
end