module BrownDispatcher
  class Interceptor
    def initialize(app)
      @app = app
    end

    def call(env)
      request_path = env["REQUEST_PATH"]
      http_host    = env["HTTP_HOST"]

      if service = Service.find_for_http_host_and_request_path(http_host, request_path)
        dispatcher = Dispatcher.new(service, request_path)
        dispatcher.dispatch(env)
        dispatcher.to_rack_result
      else
        @app.call(env)
      end
    end
  end
end
