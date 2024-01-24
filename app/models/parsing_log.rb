class ParsingLog < ApplicationRecord
  
  def self.current
    where('start_date >= ?', Time.now.beginning_of_hour).first
  end

  def self.start(count_rows)
    create(count_rows: count_rows, start_date: Time.now)
  end

  def self.done
    current_row = current
    return nil if current_row.blank? || current_row.end_date.present?
    current_row.update_column(:end_date, Time.now)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["complete_count_rows", "count_rows", "created_at", "end_date", "id", "start_date", "updated_at"]
  end

end
