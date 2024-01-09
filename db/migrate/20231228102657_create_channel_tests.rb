class CreateChannelTests < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_tests do |t|
      t.integer :subscribers
      t.text :title
      t.text :description
      t.boolean :is_verify
      t.text :avatar_url
      t.datetime :update_info_at
      t.boolean :by_web_parse
      t.boolean :by_telethon_parse
      t.datetime :updated_parse_mode_at

      t.timestamps
    end
  end
end
