redis_url = "#{$REDIS_HOST}/7"
redis_url = "#{$REDIS_HOST}/#{ENV['TEST_ENV_NUMBER'] || 0}" if Rails.env.test?

Sidekiq.configure_server do |config|
	config.redis = { url: redis_url }

  config.on(:startup) do
    schedule_file = 'config/schedule.yml'

    if File.exist?(schedule_file)
      Sidekiq::Cron::Job.destroy_all!
      Sidekiq::Cron::Job.load_from_hash!(YAML.load_file(schedule_file))
    end
  end

end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end