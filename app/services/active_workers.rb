class ActiveWorkers

  attr_accessor :worker_name

  def initialize(worker_name)
    @worker_name = worker_name.class.to_s
  end

  def is_active?
    Sidekiq::Workers.new.map(&:last).select{ |i| JSON.parse(i['payload'])['class'] == worker_name }.length > 0 rescue false
  end

end