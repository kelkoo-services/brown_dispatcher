require "spec_helper"

describe BrownDispatcher::Service do
  let(:redis) { Redis.new(db: 1) }

  before do
    redis.flushdb
    BrownDispatcher.configure do |config|
      config.redis = redis
    end
  end

  describe "#find_for_http_host_and_request_path" do
    before do
      @foo_service = BrownDispatcher::Service.register("http://foo.io", "/foo", "/bar")
                     BrownDispatcher::Service.register("http://bar.io", "/bar", "/omg")
                     BrownDispatcher::Service.register("http://baz.io", "/baz", "/kthxbai")
    end

    describe "when no service matches requested path" do
      it "should return nil" do
        BrownDispatcher::Service.find_for_http_host_and_request_path("example.com", "/fuzz/bizz").should be_nil
      end
    end

    describe "when a service matches requested path but it is disabled" do
      before do
        @foo_service.disable
      end

      it "should return nil" do
        BrownDispatcher::Service.find_for_http_host_and_request_path("example.com", "/foo/bizz").should be_nil
      end
    end

    describe "when a service matches requested path and it is enabled" do
      before do
        @foo_service.enable
      end

      it "should return new Service with appropiate hostname" do
        BrownDispatcher::Service.find_for_http_host_and_request_path("example.com", "/foo/bar").hostname.should == "http://foo.io"
      end
    end
  end
end
