require 'redis'

module BrownDispatcher
  class Service
    attr_reader :hostname

    def initialize(hostname)
      @hostname = hostname
    end

    def self.find_for_request_path(request_path)
      request_path = request_path.dup
      request_path << "/" unless request_path.end_with? "/"

      if prefix = Redis.current.hkeys("brown-dispatcher-services").detect { |k| request_path.start_with? "#{k}/" }
        hostname = Redis.current.hget("brown-dispatcher-services", prefix)
        new(hostname)
      end
    end
  end
end
