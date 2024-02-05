ActiveAdmin.register Freelancer do

	index do
    id_column
    column :login
    column :password
    column :complete_count
  end

  filter :id
  filter :login
  filter :password
  filter :complete_count

  controller do
    def new
      login = "freelancer_#{Time.now.strftime('%H%M')}#{Freelancer.count + 1}"
      password = Array.new(8) { rand(10) }.join
      Freelancer.create(login: login, password: password)
      redirect_to admin_freelancers_path
    end
  end

end
