require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ParseChannels
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    if Rails.env.development?
      $REDIS_HOST = 'redis://127.0.0.1:6379'
    elsif Rails.env.test?
      $REDIS_HOST = 'redis://127.0.0.1:6379'
    elsif Rails.env.production?
      $REDIS_HOST = 'redis://redis:6379'
    end

    config.active_job.queue_adapter = :sidekiq
  end
end
