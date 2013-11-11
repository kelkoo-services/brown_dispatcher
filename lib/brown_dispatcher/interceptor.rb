require 'httparty'

module BrownDispatcher
  class Interceptor
    def initialize(app)
      @app = app
    end

    def call(env)
      request_path = env["REQUEST_PATH"]

      if service = Service.find_for_request_path(request_path)
        uri = "#{service.hostname}#{request_path}"
        res = if env["REQUEST_METHOD"] == "POST"
                HTTParty.post uri, body: env["rack.request.form_hash"]
              else
                HTTParty.get uri, query: env["QUERY_STRING"]
              end
        [ res.code, res.headers, [ res.body ] ]
      else
        @app.call(env)
      end
    end
  end
end
