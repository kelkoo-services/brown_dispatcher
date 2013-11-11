require 'redis'
require 'httparty'

module BrownDispatcher
  class Interceptor
    def initialize(app)
      @app = app
    end

    def call(env)
      request_path = env["REQUEST_PATH"]

      if service = find_service_for_request_path(request_path)
        res = if env["REQUEST_METHOD"] == "POST"
                HTTParty.post "#{service}#{request_path}", body: env["rack.request.form_hash"]
              else
                HTTParty.get "#{service}#{request_path}", query: env["QUERY_STRING"]
              end
        [ res.code, res.headers, [ res.body ] ]
      else
        @app.call(env)
      end
    end

    private

    def find_service_for_request_path(request_path)
      request_path = request_path.dup
      request_path << "/" unless request_path.end_with? "/"

      if prefix = Redis.current.hkeys("brown-dispatcher-services").detect { |k| request_path.start_with? "#{k}/" }
        Redis.current.hget("brown-dispatcher-services", prefix)
      end
    end
  end
end
