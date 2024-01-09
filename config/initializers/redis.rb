class Redis0
  @@redis = Redis.new(url: "#{$REDIS_HOST}/0")

  class << self
    private
    def method_missing(method_name, *args)
      @@redis.send(method_name, *args)
    end
  end
end