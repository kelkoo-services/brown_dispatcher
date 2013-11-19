require "httparty"

module BrownDispatcher
  class Dispatcher
    def initialize(service, request_path)
      @service, @request_path = service, request_path
    end

    def dispatch(env)
      uri = "#{@service.hostname}#{@request_path}"
      @res = if env["REQUEST_METHOD"] == "POST"
               HTTParty.post uri, body: env["rack.request.form_hash"]
             else
               HTTParty.get uri, query: env["QUERY_STRING"]
            end
    end

    def to_rack_result
      headers = @res.headers
      headers.delete("transfer-encoding")
      [ @res.code, headers, [ @res.body ] ]
    end
  end
end
