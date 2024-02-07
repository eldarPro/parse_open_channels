ActiveAdmin.register FreelancerThemeTie do
	actions :index, :edit, :destroy

	index do
    id_column
    column :freelancer
    column :channel
    column :channel_theme
    actions
  end

  filter :id
  filter :freelancer_id
  filter :channel_theme_id
end
