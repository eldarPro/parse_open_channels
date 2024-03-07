class FreelancersController < ApplicationController
	skip_before_action :verify_authenticity_token
	before_action :authorized, only: [:index, :update_list, :set_theme]

	def index
		@freelancer     = Freelancer.find(session[:freelance_user_id])
		@count_complete = FreelancerThemeTie.count_completed(@freelancer.id)
		@themes         = ChannelTheme.all
		@lists          = FreelancerThemeTie.where(freelancer_id: @freelancer.id, active: true).includes(:channel)
		@lists          = FreelancerThemeTie.get_fresh_list(@freelancer.id) if @lists.blank?
	end

	def update_list
		FreelancerThemeTie.update_list(session[:freelance_user_id])
		redirect_to root_url
	end

	def set_theme
		tie = FreelancerThemeTie.find_by(freelancer_id: session[:freelance_user_id], channel_id: params[:channel_id])
		complete = params[:theme_id].present?
		res = tie.update_columns(complete: complete, channel_theme_id: params[:theme_id])
		count_complete = FreelancerThemeTie.count_completed(session[:freelance_user_id])
		render json: { success: res, count_complete: count_complete }
	end

	def auth
		redirect_to root_url and return if session[:freelance_user_id].present?
	end

	def check_auth
		login    = params[:login]
		password = params[:password]

		freelancer = Freelancer.find_by(login: login, password: password)

		if freelancer.present?
			session[:freelance_user_id] = freelancer.id
			sleep 2
			redirect_to root_url
		else
			flash[:notice] = 'Неверный логин или пароль'
			render :auth
		end
	end

	def logout
		session[:freelance_user_id] = nil
		redirect_to auth_path
	end

	private

	def authorized
		redirect_to auth_path and return if session[:freelance_user_id].blank?
	end

end