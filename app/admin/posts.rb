ActiveAdmin.register Post do

	index do
    id_column
    column :link
    column :views
    column :statistic
    column :links
    column :is_repost
    column :updated_at
    actions
  end

	filter :channel_id_eq

end
