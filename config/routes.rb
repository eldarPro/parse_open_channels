require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "freelancers#index"

  get 'auth' => 'freelancers#auth', as: :auth
  get 'freelancers/check_auth' => 'freelancers#check_auth'
  get 'freelancers/logout' => 'freelancers#logout'
  get 'freelancers/update_list' => 'freelancers#update_list'
  get 'freelancers/set_theme' => 'freelancers#set_theme'

  mount Sidekiq::Web => '/jobs'
end
