# config valid for current version and patch releases of Capistrano
lock "~> 3.18.0"

set :application, "parse"
set :repo_url, "git@github.com:eldarPro/parse_open_channels.git"
set :branch, "main"


set :puma_threads, [1, 6]
set :puma_workers, 4

set :user, 'deployer'
set :pty, true
set :use_sudo, false
set :stage, :production
set :deploy_via, :remote_cache
set :deploy_to, "/home/#{fetch(:user)}/#{fetch :application}"
set :puma_bind, "unix:///home/rails/apps/mysite/shared/tmp/sockets/mysite-puma.sock"

set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log, "#{release_path}/log/puma.error.log"
set :ssh_options, { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true # Change to false when not using ActiveRecord

set :rbenv_type, :user
set :rbenv_ruby, '3.3.0'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_roles, :all

set :sidekiq_default_hooks, -> { false }

append :linked_files, "config/master.key"
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system', 'public/uploads'

namespace :sidekiq do
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, 'sidekiq'
    end
  end

  task :stop do
    on roles(:app) do
      execute :sudo, :systemctl, :stop, 'sidekiq'
    end
  end

  task :start do
    on roles(:app) do
      execute :sudo, :systemctl, :start, 'sidekiq'
    end
  end
end

after 'deploy:restart', 'sidekiq:restart'

# namespace :deploy do
#   desc "Run seed"
#   task :seed do
#     on roles(:all) do
#       within current_path do
#         execute :bundle, :exec, 'rails', 'db:seed', 'RAILS_ENV=production'
#       end
#     end
#   end

#   after :migrating, :seed
# end

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
