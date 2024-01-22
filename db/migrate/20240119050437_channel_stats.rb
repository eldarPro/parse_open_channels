class ChannelStats < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_stats do |t|
      t.bigint :channel_id
      t.integer :subscribers
      t.string :title
      t.datetime :created_at, precision: nil, null: false
      t.text :description
      t.boolean :prometheus, default: false, null: false
      t.integer :average_views
    end

    add_index :channel_stats, :channel_id
  end
end
