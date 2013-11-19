require 'redis'

module BrownDispatcher
  class Service
    attr_reader :hostname

    def initialize(hostname)
      @hostname = hostname
    end

    def self.register(hostname, *prefixes)
      prefixes.each do |prefix|
        Redis.current.hset("brown-dispatcher-services:#{prefix}", "hostname", hostname)
        Redis.current.hset("brown-dispatcher-services:#{prefix}", "enabled", true)
      end
    end

    def enable
      self.class.redis_keys_for_hostname(hostname).each do |k|
        Redis.current.hset(k, "enabled", true)
      end
    end

    def disable
      self.class.redis_keys_for_hostname(hostname).each do |k|
        Redis.current.hset(k, "enabled", false)
      end
    end

    def self.find_for_http_host_and_request_path(http_host, request_path)
      if key = redis_key_for(http_host, request_path)
        hostname = Redis.current.hget(key, "hostname")
        new(hostname)
      end
    end

    private

    def self.redis_key_for(http_host, request_path)
      request_path = request_path.dup
      request_path << "/" unless request_path.end_with? "/"

      redis_keys.detect do |k|
        next unless Redis.current.hget(k, "enabled") == "true"
        next if http_host == Redis.current.hget(k, "hostname").sub(%r{^https?://}, "")

        prefix = k.sub %r{^brown-dispatcher-services:}, ""
        request_path.start_with? "#{prefix}/"
      end
    end

    def self.redis_keys
      Redis.current.keys("brown-dispatcher-services:*")
    end

    def self.redis_keys_for_hostname(hostname)
      redis_keys.select do |k|
        Redis.current.hget(k, "hostname") == hostname
      end
    end
  end
end
