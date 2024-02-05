class ChannelTheme < ApplicationRecord

  def display_name
    title
  end

  def self.ransackable_attributes(auth_object = nil)
    ["id", "title"]
  end

end
