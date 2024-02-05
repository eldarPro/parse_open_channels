class Freelancer < ApplicationRecord

  validates :login, uniqueness: true, presence: true

  def display_name
    login
  end

  def self.ransackable_attributes(auth_object = nil)
    ["complete_count", "created_at", "id", "login", "password", "updated_at"]
  end

end
