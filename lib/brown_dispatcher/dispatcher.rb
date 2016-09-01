require "httparty"

module BrownDispatcher
  class Dispatcher
    include HTTParty

    no_follow true

    def initialize(hostname, request_path, env)
      @hostname, @request_path, @env = hostname, request_path, env
    end

    def dispatch
      uri = "#{@hostname}#{@request_path}"
      @res = get_response(uri)
    end

    def to_rack_result
      headers = @res.respond_to?(:headers) ? @res.headers : @res.to_hash
      headers.delete("transfer-encoding")
      [ @res.code, headers, [ @res.body ] ]
    end

    private

    def get_response(uri)
      basic_auth = get_basic_auth_from(uri)

      if @env["REQUEST_METHOD"] == "POST"
        self.class.post uri, body: post_params, basic_auth: basic_auth
      else
        self.class.get uri, query: get_params, basic_auth: basic_auth
      end
    rescue HTTParty::RedirectionTooDeep => e
      e.response
    end

    def get_basic_auth_from(uri)
      userinfo = URI.parse(uri).userinfo
      if userinfo
        username, password = userinfo.split(":")
        { username: username, password: password }
      end
    end

    def get_params
      query_string = @env["QUERY_STRING"] || ""
      params = CGI.parse(query_string)
      merge_user_auth! params
      URI.encode_www_form(params)
    end

    def post_params
      params = @env["rack.request.form_hash"] || {}
      merge_user_auth! params
      params
    end

    def merge_user_auth!(params)
      request = ActionDispatch::Request.new(@env)
      user_auth = request.cookie_jar.signed[:user_auth]
      params.update(user_auth: user_auth) if user_auth
    end
  end
end
