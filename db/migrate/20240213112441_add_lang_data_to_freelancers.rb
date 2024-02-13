class AddLangDataToFreelancers < ActiveRecord::Migration[7.0]
  def change
    add_column :freelancers, :set_ru_lang, :boolean, default: true
    add_column :freelancers, :set_en_lang, :boolean, default: true
    add_column :freelancers, :set_other_lang, :boolean, default: true

    add_column :freelancer_theme_ties, :lang, :string, index: true
  end
end
