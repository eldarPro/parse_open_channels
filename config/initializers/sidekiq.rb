redis_url = "#{$REDIS_HOST}/5"
redis_url = "#{$REDIS_HOST}/#{ENV['TEST_ENV_NUMBER'] || 0}" if Rails.env.test?

Sidekiq.configure_server do |config|
	config.redis = { url: redis_url }

  config.on(:startup) do
    schedule_file = 'config/schedule.yml'

    if File.exist?(schedule_file)
      schedule = YAML.load_file(schedule_file)

      Sidekiq::Cron::Job.load_from_hash!(schedule, source: 'schedule')
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end