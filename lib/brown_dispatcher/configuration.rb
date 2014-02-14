module BrownDispatcher
  class Configuration
    def redis=(redis)
      @redis = redis
    end

    def redis
      @redis ||= Redis.current
    end
  end
end
