require "spec_helper"

describe BrownDispatcher::Interceptor do
  let(:app) { double }
  let(:env) do
    {
      "REQUEST_METHOD" => "GET",
      "REQUEST_PATH" => "/foo/bar"
    }
  end
  let(:interceptor) { BrownDispatcher::Interceptor.new(app) }

  before { FakeWeb.allow_net_connect = false }

  describe "get requests" do
    before { env.update("QUERY_STRING" => "foo=bar") }

    it "should delegate to the right service, if any" do
      FakeWeb.register_uri :get, "http://foobar.io/foo/bar?foo=bar", body: "get response from http://foobar.io/foo/bar"
      BrownDispatcher::Service.should_receive(:find_for_request_path).with("/foo/bar").and_return(BrownDispatcher::Service.new("http://foobar.io"))
      res = interceptor.call(env)
      res.should == [ 200, {}, [ "get response from http://foobar.io/foo/bar" ] ]
    end

    it "should call call to app if no requested service" do
      BrownDispatcher::Service.should_receive(:find_for_request_path).with("/foo/bar").and_return(nil)
      app.should_receive(:call).with(env)
      interceptor.call(env)
    end
  end

  describe "post requests" do
    before { env.update("REQUEST_METHOD" => "POST", "rack.request.form_hash" => { "foo" => "bar" }) }

    it "should delegate to the right service, if any" do
      FakeWeb.register_uri :post, "http://foobar.io/foo/bar", body: "post response from http://foobar.io/foo/bar"
      BrownDispatcher::Service.should_receive(:find_for_request_path).with("/foo/bar").and_return(BrownDispatcher::Service.new("http://foobar.io"))
      res = interceptor.call(env)
      res.should == [ 200, {}, [ "post response from http://foobar.io/foo/bar" ] ]
      FakeWeb.last_request.body.should == "foo=bar"
    end

    it "should call call to app if no requested service" do
      BrownDispatcher::Service.should_receive(:find_for_request_path).with("/foo/bar").and_return(nil)
      app.should_receive(:call).with(env)
      interceptor.call(env)
    end
  end
end