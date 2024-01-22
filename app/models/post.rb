class Post < ApplicationRecord
  belongs_to :channel

  def self.ransackable_scopes(_auth_object = nil)
    [:channel_id_eq, :link_cont, :link_eq, :link_start, :link_end,
     :kind_eq, :kind_cont, :kind_start, :kind_end,
     :views_eq, :views_cont, :views_start, :views_end]
  end

  def self.ransackable_associations(auth_object = nil)
    [:channel]
  end

  def self.ransackable_attributes(auth_object = nil)
    [:campaign, :channel_id, :created_at, :deleted_at, :feed_hours, :has_external_links, 
     :has_photo, :has_video, :html, :id, :is_checked_clicks, :is_marking, :is_repost, 
     :kind, :last_parsed_at, :link, :links, :next_post_at, :order_channel_id, :prometheus_id, 
     :published_at, :scheduled_parsing_at, :screenshot, :skip_screen, :statistic, :tg_id, 
     :top_hours, :updated_at, :views]
  end
end