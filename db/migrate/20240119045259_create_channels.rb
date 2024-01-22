class CreateChannels < ActiveRecord::Migration[7.0]
  def change
    create_table :channels do |t|
      t.string :name
      t.string :joinchat
      t.string :tg_id
      t.string :title
      t.text :description
      t.boolean :inner, default: false
      t.datetime :get_last_posts_at, default: "2000-01-01 00:00:00", null: false
      t.datetime :update_info_at, default: "2000-01-01 00:00:00", null: false
      t.integer :subscribers, default: 0
      t.boolean :is_private
      t.datetime :apr_calculated_at, default: "2000-01-01 00:00:00", null: false
      t.jsonb :stat, default: [], array: true
      t.boolean :broadcast
      t.string :new_tg_id
      t.string :lang
      t.datetime :last_post_date
      t.boolean :is_verify
      t.integer :last_post_id
      t.boolean :by_web_parse
      t.boolean :by_telethon_parse
      t.datetime :updated_parse_mode_at
      t.text :avatar_url
      t.boolean :from_external_link, default: false
      t.float :last_eternal_err, default: 0.0
      t.float :last_eternal_apr, default: 0.0
      t.integer :average_views, default: 0
      t.datetime :avatar_updated_at
      t.boolean :is_empty, default: false
      t.timestamps
    end

    add_index :channels, :tg_id
    add_index :channels, :name
    add_index :channels, :joinchat
  end
end
