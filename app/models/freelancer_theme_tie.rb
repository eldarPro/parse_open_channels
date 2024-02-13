class FreelancerThemeTie < ApplicationRecord

	belongs_to :channel, class_name: 'MainDb::Channel'
	belongs_to :channel_theme
  belongs_to :freelancer

	validates :channel_id, presence: true

  def self.get_fresh_list(freelancer_id)

    freelancer = Freelancer.find(freelancer_id)
    langs = []
    langs << 'ru' if freelancer.set_ru_lang?
    langs << 'en' if freelancer.set_en_lang?
    langs << nil  if freelancer.set_other_lang?

    res = FreelancerThemeTie.where(lang: langs, complete: false, active: false).order("RANDOM()").limit(10)
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

  def self.complete_eq(val)
    where(complete: (val.to_s == 'Yes'))
  end

  def self.private_eq(val)
    res = self
    res = joins(:channel).where(channels: { by_telethon_parse: true })   if val == 'Yes'
    res = joins(:channel).where(channels: { by_web_parse: [true, nil] }) if val == 'No'
    res
  end

  def self.ransackable_scopes(_auth_object = nil)
    [:complete_eq, :private_eq]
  end

  def self.ransackable_associations(auth_object = nil)
    ["channel_theme", "freelancer"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["channel_theme_id", "freelancer_id", "id"]
  end
end