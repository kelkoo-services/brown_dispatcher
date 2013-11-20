require "spec_helper"

describe BrownDispatcher::Dispatcher do
  let(:env) do
    {
      "REQUEST_METHOD" => "GET",
      "REQUEST_PATH" => "/foo/bar",
      "action_dispatch.cookies" => double("Cookies", signed: {})
    }
  end
  let(:service) { double("Service", hostname: "http://foobar.io") }
  let(:request_path) { env["REQUEST_PATH"] }

  describe "get requests" do
    describe "without params or user_auth" do
      it "should delegate to the service" do
        FakeWeb.register_uri :get, "http://foobar.io/foo/bar", body: "get response from http://foobar.io/foo/bar"
        dispatcher = BrownDispatcher::Dispatcher.new(service, request_path)
        dispatcher.dispatch(env)
        dispatcher.to_rack_result.should == [ 200, {}, [ "get response from http://foobar.io/foo/bar" ] ]
      end
    end

    describe "with params" do
      before { env.update("QUERY_STRING" => "foo=bar") }

      it "should delegate to the service" do
        FakeWeb.register_uri :get, "http://foobar.io/foo/bar?foo=bar", body: "get response from http://foobar.io/foo/bar"
        dispatcher = BrownDispatcher::Dispatcher.new(service, request_path)
        dispatcher.dispatch(env)
        dispatcher.to_rack_result.should == [ 200, {}, [ "get response from http://foobar.io/foo/bar" ] ]
      end
    end

    describe "with user_auth" do
      before { env["action_dispatch.cookies"].signed.update(user_auth: "1234") }

      it "should delegate to the service" do
        FakeWeb.register_uri :get, "http://foobar.io/foo/bar?user_auth=1234", body: "get response from http://foobar.io/foo/bar"
        dispatcher = BrownDispatcher::Dispatcher.new(service, request_path)
        dispatcher.dispatch(env)
        dispatcher.to_rack_result.should == [ 200, {}, [ "get response from http://foobar.io/foo/bar" ] ]
      end
    end
  end

  describe "post requests" do
    before { env.update("REQUEST_METHOD" => "POST") }

    describe "without params or user_auth" do
      it "should delegate to the service" do
        FakeWeb.register_uri :post, "http://foobar.io/foo/bar", body: "post response from http://foobar.io/foo/bar"
        dispatcher = BrownDispatcher::Dispatcher.new(service, request_path)
        dispatcher.dispatch(env)
        dispatcher.to_rack_result.should == [ 200, {}, [ "post response from http://foobar.io/foo/bar" ] ]
        FakeWeb.last_request.body.should == ""
      end
    end

    describe "with params" do
      before { env.update("rack.request.form_hash" => { "foo" => "bar" }) }

      it "should delegate to the service" do
        FakeWeb.register_uri :post, "http://foobar.io/foo/bar", body: "post response from http://foobar.io/foo/bar"
        dispatcher = BrownDispatcher::Dispatcher.new(service, request_path)
        dispatcher.dispatch(env)
        dispatcher.to_rack_result.should == [ 200, {}, [ "post response from http://foobar.io/foo/bar" ] ]
        FakeWeb.last_request.body.should == "foo=bar"
      end
    end

    describe "with user_auth" do
      before { env["action_dispatch.cookies"].signed.update(user_auth: "1234") }

      it "should delegate to the service" do
        FakeWeb.register_uri :post, "http://foobar.io/foo/bar", body: "post response from http://foobar.io/foo/bar"
        dispatcher = BrownDispatcher::Dispatcher.new(service, request_path)
        dispatcher.dispatch(env)
        dispatcher.to_rack_result.should == [ 200, {}, [ "post response from http://foobar.io/foo/bar" ] ]
        FakeWeb.last_request.body.should == "user_auth=1234"
      end
    end
  end
end
