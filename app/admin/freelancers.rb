ActiveAdmin.register Freelancer do
  permit_params :login, :password, :note, :set_ru_lang, :set_en_lang, :set_other_lang

	index do
    id_column
    column :login
    column :password
    column :complete_count do |row|
      row.freelancer_theme_ties.select{ _1.complete }.length
    end
    column :set_ru_lang
    column :set_en_lang
    column :set_other_lang
    column :note
    actions
  end

  filter :id
  filter :login
  filter :password
  filter :note

  form do |f|
    f.inputs 'Freelancer' do
      f.input :note
      f.input :set_ru_lang
      f.input :set_en_lang
      f.input :set_other_lang
      f.submit
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes(:freelancer_theme_ties)
    end

    def create
      login = "freelancer_#{Time.now.strftime('%H%M')}#{Freelancer.count + 1}"
      password = Array.new(8) { rand(10) }.join
      Freelancer.create({login: login, password: password, 
                         note: params[:freelancer][:note],
                         set_ru_lang: params[:freelancer][:set_ru_lang],
                         set_en_lang: params[:freelancer][:set_en_lang],
                         set_other_lang: params[:freelancer][:set_other_lang]})

      redirect_to admin_freelancers_path
    end
  end

end
