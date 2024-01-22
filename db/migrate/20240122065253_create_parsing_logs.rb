class CreateParsingLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :parsing_logs do |t|
      t.integer :count_rows, default: 0, null: false
      t.integer :complete_count_rows, default: 0, null: false
      t.datetime :start_date
      t.datetime :end_date
      t.timestamps
    end
  end
end
