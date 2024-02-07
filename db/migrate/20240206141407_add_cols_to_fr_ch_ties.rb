class AddColsToFrChTies < ActiveRecord::Migration[7.0]
  def change
    add_column :freelancer_theme_ties, :active, :boolean, default: false, index: true
    add_column :freelancer_theme_ties, :complete, :boolean, default: false, index: true

    add_index :freelancer_theme_ties, :freelancer_id
  end
end
