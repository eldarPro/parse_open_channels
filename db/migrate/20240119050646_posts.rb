class Posts < ActiveRecord::Migration[7.0]
  def change
    create_table "posts", force: :cascade do |t|
      t.bigint :channel_id
      t.string :link, null: false
      t.string :kind
      t.integer :views
      t.boolean :has_photo
      t.boolean :has_video
      t.decimal :top_hours, default: "0.0", null: false
      t.decimal :feed_hours, default: "0.0", null: false
      t.datetime :published_at, precision: nil
      t.datetime :deleted_at, precision: nil
      t.datetime :next_post_at, precision: nil
      t.text :html
      t.jsonb :links
      t.jsonb :statistic, default: [], null: false
      t.boolean :skip_screen, default: false, null: false
      t.integer :prometheus_id
      t.integer :tg_id, null: false
      t.boolean :campaign, default: false, null: false
      t.string :screenshot
      t.integer :order_channel_id
      t.boolean :has_external_links
      t.datetime :scheduled_parsing_at
      t.datetime :last_parsed_at
      t.boolean :is_marking
      t.boolean :is_repost, default: false
      t.boolean :is_checked_clicks, default: false
      t.timestamps
    end

    add_index :posts, :tg_id
    add_index :posts, :link, unique: true
    add_index :posts, :channel_id
    add_index :posts, :campaign
  end
end
