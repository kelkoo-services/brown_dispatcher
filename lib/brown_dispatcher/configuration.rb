module BrownDispatcher
  class Configuration
    attr_accessor :redis

    def initialize
    end

    def redis
      @redis ||= Redis.current
    end
  end
end
