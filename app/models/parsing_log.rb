class ParsingLog < ApplicationRecord
  
  def self.current
    where('start_date >= ?', Time.now.beginning_of_hour).first
  end

  def self.start(count_rows)
    create(count_rows: count_rows, start_date: Time.now)
  end

  def self.incr(count)
    return nil if count.blank?
    current_row = current
    return nil if current_row.blank?
    new_count = current_row.complete_count_rows + count.to_i
    current_row.update_column(:complete_count_rows, new_count)
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
