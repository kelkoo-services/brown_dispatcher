require "spec_helper"

describe BrownDispatcher::Interceptor do
  let(:app) { double("Application") }
  let(:env) do
    {
      "HTTP_X_BROWN_DISPATCHER" => "true",
      "HTTP_HOST" => "example.com",
      "REQUEST_METHOD" => "GET",
      "REQUEST_PATH" => "/foo/bar"
    }
  end
  let(:interceptor) { BrownDispatcher::Interceptor.new(app) }

  let(:service) { double("Service", hostname: "http://foobar.io") }
  let(:dispatcher) { double("Dispatcher") }

  describe "requests" do
    it "should delegate to the right service, if any" do
      BrownDispatcher::Service.should_receive(:find_for_http_host_and_request_path).with("example.com", "/foo/bar").and_return(service)
      BrownDispatcher::Dispatcher.should_receive(:new).with(service.hostname, "/foo/bar", env).and_return(dispatcher)
      dispatcher.should_receive(:dispatch)
      dispatcher.should_receive(:to_rack_result).and_return([ 200, {}, [ "response from http://foobar.io/foo/bar" ] ])
      interceptor.call(env).should == [ 200, {}, [ "response from http://foobar.io/foo/bar" ] ]
    end

    it "should call call to app if no requested service" do
      BrownDispatcher::Service.should_receive(:find_for_http_host_and_request_path).with("example.com", "/foo/bar").and_return(nil)
      app.should_receive(:call).with(env)
      interceptor.call(env)
    end
  end
end
