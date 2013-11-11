require "spec_helper"

describe BrownDispatcher::Dispatcher do
  let(:env) do
    {
      "REQUEST_METHOD" => "GET",
      "REQUEST_PATH" => "/foo/bar"
    }
  end
  let(:service) { double("Service", hostname: "http://foobar.io") }
  let(:request_path) { env["REQUEST_PATH"] }

  describe "get requests" do
    before { env.update("QUERY_STRING" => "foo=bar") }

    it "should delegate to the service" do
      FakeWeb.register_uri :get, "http://foobar.io/foo/bar?foo=bar", body: "get response from http://foobar.io/foo/bar"
      dispatcher = BrownDispatcher::Dispatcher.new(service, request_path)
      dispatcher.dispatch(env)
      dispatcher.to_rack_result.should == [ 200, {}, [ "get response from http://foobar.io/foo/bar" ] ]
    end
  end

  describe "post requests" do
    before { env.update("REQUEST_METHOD" => "POST", "rack.request.form_hash" => { "foo" => "bar" }) }

    it "should delegate to the service" do
      FakeWeb.register_uri :post, "http://foobar.io/foo/bar", body: "post response from http://foobar.io/foo/bar"
      dispatcher = BrownDispatcher::Dispatcher.new(service, request_path)
      dispatcher.dispatch(env)
      dispatcher.to_rack_result.should == [ 200, {}, [ "post response from http://foobar.io/foo/bar" ] ]
      FakeWeb.last_request.body.should == "foo=bar"
    end
  end
end
