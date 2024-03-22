class ActiveWorkers

  attr_accessor :worker_name

  def initialize(worker_name)
    @worker_name = worker_name
  end

  def is_active?
    Sidekiq::Workers.new.map(&:last).find{ |i| JSON.parse(i['payload'])['class'] == worker_name }.present? rescue false
  end

end