class AddNoteToFreelancers < ActiveRecord::Migration[7.0]
  def change
    add_column :freelancers, :note, :text
  end
end
