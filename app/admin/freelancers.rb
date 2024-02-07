ActiveAdmin.register Freelancer do
  permit_params :login, :password, :note

	index do
    id_column
    column :login
    column :password
    column :complete_count do |row|
      row.freelancer_theme_ties.select{ _1.complete }.length
    end
    column :note
    actions
  end

  filter :id
  filter :login
  filter :password
  filter :note

  controller do
     def scoped_collection
      end_of_association_chain.includes(:freelancer_theme_ties)
    end

    def new
      login = "freelancer_#{Time.now.strftime('%H%M')}#{Freelancer.count + 1}"
      password = Array.new(8) { rand(10) }.join
      Freelancer.create(login: login, password: password)
      redirect_to admin_freelancers_path
    end
  end

end
