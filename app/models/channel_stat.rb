class ChannelStat < ApplicationRecord

	def self.ransackable_attributes(auth_object = nil)
    ["average_views", "channel_id", "created_at", "description", "id", "prometheus", "subscribers", "title"]
  end
end
