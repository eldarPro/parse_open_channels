class FreelancerThemeTie < ApplicationRecord

	belongs_to :freelancer
	belongs_to :channel_theme

	validates :freelancer_id, presence: true
	validates :channel_theme_id, presence: true

  def self.ransackable_associations(auth_object = nil)
    ["channel_theme", "freelancer"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["channel_theme_id", "freelancer_id", "id"]
  end
end