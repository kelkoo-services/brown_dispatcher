require 'redis'

module BrownDispatcher
  class Service
    attr_reader :hostname

    def initialize(hostname)
      @hostname = hostname
    end

    def self.register(hostname, *prefixes)
      prefixes.each do |prefix|
        redis.hset("brown-dispatcher-services:#{prefix}", "hostname", hostname)
        redis.hset("brown-dispatcher-services:#{prefix}", "enabled", true)
      end
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
        next if http_host == redis.hget(k, "hostname").sub(%r{^https?://}, "")

        prefix = k.sub %r{^brown-dispatcher-services:}, ""
        request_path.start_with? "#{prefix}/"
      end
    end

    def self.redis_keys
      redis.keys("brown-dispatcher-services:*")
    end

    def self.redis_keys_for_hostname(hostname)
      redis_keys.select do |k|
        redis.hget(k, "hostname") == hostname
      end
    end

    def self.redis
      BrownDispatcher.configuration.redis
    end

    def redis
      self.class.redis
    end
  end
end
