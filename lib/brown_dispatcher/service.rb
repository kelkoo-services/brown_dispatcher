require 'redis'

module BrownDispatcher
  class Service
    attr_reader :hostname

    def initialize(hostname)
      @hostname = hostname
    end

    def self.register(hostname, *prefixes)
      prefixes.each do |prefix|
        redis.lpush("brown-dispatcher-services", prefix)
        redis.hset("brown-dispatcher-services:#{prefix}", "hostname", hostname)
        redis.hset("brown-dispatcher-services:#{prefix}", "enabled", true)
      end
      new(hostname)
    end

    def enable
      self.class.redis_keys_for_hostname(hostname).each do |k|
        redis.hset(k, "enabled", true)
      end
    end

    def disable
      self.class.redis_keys_for_hostname(hostname).each do |k|
        redis.hset(k, "enabled", false)
      end
    end

    def self.find_for_http_host_and_request_path(http_host, request_path)
      if key = redis_key_for(http_host, request_path)
        hostname = redis.hget(key, "hostname")
        new(hostname)
      end
    end

    private

    def self.redis_key_for(http_host, request_path)
      request_path = (request_path || "").dup
      request_path << "/" unless request_path.end_with? "/"

      redis_keys.detect do |k|
        next unless redis.hget(k, "enabled") == "true"
        next if same_host?(http_host, redis.hget(k, "hostname"))

        prefix = k.sub %r{^brown-dispatcher-services:}, ""
        request_path.start_with? "#{prefix}/"
      end
    end

    def self.redis_keys
      redis.lrange("brown-dispatcher-services", 0, -1).map do |prefix|
        "brown-dispatcher-services:#{prefix}"
      end
    end

    def self.redis_keys_for_hostname(hostname)
      redis_keys.select do |k|
        redis.hget(k, "hostname") == hostname
      end
    end

    def self.same_host?(http_host, redis_host)
      redis_host.sub!(%r{^https?://}, "")
      redis_host.sub!(%r{^[^:]+:[^@]+@}, "")
      http_host == redis_host
    end

    def self.redis
      BrownDispatcher.configuration.redis
    end

    def redis
      self.class.redis
    end
  end
end
