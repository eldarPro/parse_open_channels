class FreelancerThemeTie < ApplicationRecord

	belongs_to :channel, class_name: 'MainDb::Channel'
	belongs_to :channel_theme
  belongs_to :freelancer

	validates :channel_id, presence: true

  def self.get_fresh_list(freelancer_id)
    res = FreelancerThemeTie.where(complete: false, active: false).order("RANDOM()").limit(10)
    res.update_all(freelancer_id: freelancer_id, active: true)
    res
  end

  def self.update_list(freelancer_id)
    FreelancerThemeTie.where(freelancer_id: freelancer_id, complete: [true, false], active: true).update_all(active: false)
    get_fresh_list(freelancer_id)
  end

  def self.count_completed(freelancer_id)
    FreelancerThemeTie.where(freelancer_id: freelancer_id, complete: true).count
  end

  def self.fill_data
    return false if FreelancerThemeTie.count > 0

    MainDb::Channel.select(:id).find_in_batches(batch_size: 1000) do |channels|
      insert_values = []
      channels.each{ |c| insert_values << { channel_id: c.id } }
      FreelancerThemeTie.insert_all(insert_values)
    end

    true
  end

  def self.ransackable_associations(auth_object = nil)
    ["channel_theme", "freelancer"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["channel_theme_id", "freelancer_id", "id"]
  end
end