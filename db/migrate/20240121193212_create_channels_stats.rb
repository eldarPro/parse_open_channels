class CreateChannelsStats < ActiveRecord::Migration[7.0]
  def change
    create_table :channels_stats do |t|
      t.bigint :channel_id, null: false
      t.integer :subscribers, null: false
      t.string :title
      t.text :description
      t.integer :average_views
      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
  end
end
