class Channel < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :channel_stats, dependent: :destroy

  validates :name, presence: true
  
  def self.posts_id_eq(id)
    posts.where(channel_id: id)
  end

  def self.channel_stats_id_eq(id)
    channel_stats.where(channel_id: id)
  end

  def self.ransackable_scopes(_auth_object = nil)
    [:posts_id_eq, :channel_stats_id_eq]
  end

  def self.ransackable_associations(auth_object = nil)
    [:posts, :channel_stats]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["apr_calculated_at", "avatar_updated_at", "avatar_url", "average_views", "broadcast", "by_telethon_parse", "by_web_parse", "created_at", "description", "from_external_link", "get_last_posts_at", "id", "inner", "is_empty", "is_private", "is_verify", "joinchat", "lang", "last_eternal_apr", "last_eternal_err", "last_post_date", "name", "new_tg_id", "stat", "subscribers", "tg_id", "title", "update_info_at", "updated_at", "updated_parse_mode_at"]
  end

end
