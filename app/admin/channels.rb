ActiveAdmin.register Channel do

	index do
    id_column
    column :name
    column :joinchat
    column :tg_id
    column :title
    column :description
    column :inner
    column :subscribers
    column :average_views
    column :update_info_at
    actions
  end

  filter :id
  filter :name
  filter :joinchat
  filter :tg_id
  filter :inner
  filter :subscribers
  filter :average_views

end
