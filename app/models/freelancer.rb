class Freelancer < ApplicationRecord
  has_many :freelancer_theme_ties, class_name: 'FreelancerThemeTie'
  validates :login, uniqueness: true, presence: true

  def display_name
    login
  end

  def self.ransackable_associations(auth_object = nil)
    ["freelancer_theme_ties"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["note", "created_at", "id", "login", "password", "updated_at"]
  end

end
