require "brown_dispatcher/version"
require "brown_dispatcher/configuration"
require "brown_dispatcher/interceptor"
require "brown_dispatcher/service"
require "brown_dispatcher/dispatcher"

module BrownDispatcher
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end
end
