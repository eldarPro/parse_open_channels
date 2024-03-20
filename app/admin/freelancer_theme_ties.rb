ActiveAdmin.register FreelancerThemeTie, as: 'FreelancerChannelTheme' do
	actions :index
  permit_params :freelancer_id, :channel_id, :channel_theme_id, :active, :complete

	index do
    id_column
    column :freelancer
    column :channel do |item|
      if item.channel.present?
        link = item.channel.name || item.channel.joinchat
        link_to link, "https://t.me/s/#{link}"
      end
    end
    column :channel_theme
    column :active
    column :complete
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
