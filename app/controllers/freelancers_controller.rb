class FreelancersController < ApplicationController

	def index
		redirect_to auth_path and return if session[:freelance_user_id].blank?

		
	end

	def auth

	end

end