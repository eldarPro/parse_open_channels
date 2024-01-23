namespace :sidekiq do
  task :install do
    on roles fetch(:sidekiq_roles) do |role|
      switch_user(role) do
        case fetch(:init_system)
        when :systemd
          create_systemd_template
          execute :systemctl, "--user", "enable", fetch(:service_unit_name)
        end
      end
    end
  end

  def fetch_systemd_unit_path
    home_dir = capture :pwd
    File.join(home_dir, ".config", "systemd", "user")
  end

  def create_systemd_template
    search_paths = [
      File.expand_path(
        File.join(*%w[.. .. .. .. config deploy templates sidekiq.service.capistrano.erb]),
        __FILE__
      ),
    ]
    template_path = search_paths.detect {|path| File.file?(path)}
    template = File.read(template_path)
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)
    execute :mkdir, "-p", systemd_path
    upload!(
      StringIO.new(ERB.new(template).result(binding)),
      "#{systemd_path}/#{fetch :service_unit_name}"
    )
    execute :systemctl, "--user", "daemon-reload"
  end
end