ActiveAdmin.register ChannelTheme do

	index do
    id_column
    column :title
  end

  filter :id
  filter :title
end
