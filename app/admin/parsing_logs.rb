ActiveAdmin.register ParsingLog do

	index do
    column :start_date
    column :end_date
    column :count_rows
    column :complete_count_rows
  end

end
