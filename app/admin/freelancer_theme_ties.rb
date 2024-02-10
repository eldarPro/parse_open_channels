ActiveAdmin.register FreelancerThemeTie do
	actions :index, :edit
  permit_params :freelancer_id, :channel_id, :channel_theme_id, :active, :complete

	index do
    id_column
    column :freelancer
    column :channel
    column :channel_theme
    column :active
    column :complete
    actions
  end

  filter :id
  filter :freelancer_id
  filter :channel_theme_id
  filter :private_eq, as: :select, collection: ['Yes', 'No']
  filter :complete, as: :select, collection: ['Yes', 'No']

  controller do
    def scoped_collection
      end_of_association_chain.includes(:channel, :channel_theme)
    end
  end

end
