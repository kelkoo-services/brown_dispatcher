module BrownDispatcher
  class Configuration
    def redis=(redis)
      @redis = redis
      redis_version = redis.info["redis_version"].split(".").map(&:to_i)
      @redis_supports_scan = (redis_version <=> [2, 8, 0]) >= 0
    end

    def redis
      @redis ||= Redis.current
    end

    def redis_supports_scan?
      @redis_supports_scan
    end
  end
end
