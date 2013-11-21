require "httparty"

module BrownDispatcher
  class Dispatcher
    include HTTParty

    no_follow true

    def initialize(service, request_path)
      @service, @request_path = service, request_path
    end

    def dispatch(env)
      uri = "#{@service.hostname}#{@request_path}"
      @res = get_response(env, uri)
    end

    def to_rack_result
      headers = @res.to_hash
      headers.delete("transfer-encoding")
      [ @res.code, headers, [ @res.body ] ]
    end

    private

    def get_response(env, uri)
      if env["REQUEST_METHOD"] == "POST"
        self.class.post uri, body: post_params_for(env)
      else
        self.class.get uri, query: get_params_for(env)
      end
    rescue HTTParty::RedirectionTooDeep => e
      e.response
    end

    def get_params_for(env)
      query_string = env["QUERY_STRING"] || ""
      params = CGI.parse(query_string)
      merge_user_auth! env, params
      URI.encode_www_form(params)
    end

    def post_params_for(env)
      params = env["rack.request.form_hash"] || {}
      merge_user_auth! env, params
      params
    end

    def merge_user_auth!(env, params)
      signed_cookies = env["action_dispatch.cookies"].signed
      user_auth = signed_cookies[:user_auth]

      params.update(user_auth: user_auth) if user_auth
    end
  end
end
