class AddChannelItToFreelancerThemeTies < ActiveRecord::Migration[7.0]
  def change
    add_column :freelancer_theme_ties, :channel_id, :integer
  end
end
