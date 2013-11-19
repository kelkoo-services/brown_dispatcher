require "spec_helper"

describe BrownDispatcher::Service do
  let(:redis) { double("Redis") }

  before do
    BrownDispatcher.configure do |config|
      config.redis = redis
    end
  end

  describe "#find_for_http_host_and_request_path" do
    before do
      expect(redis).to receive(:keys).with("brown-dispatcher-services:*").and_return(["brown-dispatcher-services:/bar", "brown-dispatcher-services:/foo", "brown-dispatcher-services:/baz"])
      expect(redis).to receive(:hget).with("brown-dispatcher-services:/bar", "enabled").and_return("true")
      expect(redis).to receive(:hget).with("brown-dispatcher-services:/bar", "hostname").and_return("foo.biz")
    end

    describe "when no service matches requested path" do
      before do
        expect(redis).to receive(:hget).with("brown-dispatcher-services:/foo", "enabled").and_return("true")
        expect(redis).to receive(:hget).with("brown-dispatcher-services:/foo", "hostname").and_return("foo.biz")
        expect(redis).to receive(:hget).with("brown-dispatcher-services:/baz", "enabled").and_return("true")
        expect(redis).to receive(:hget).with("brown-dispatcher-services:/baz", "hostname").and_return("foo.biz")
      end

      it "should return nil" do
        BrownDispatcher::Service.find_for_http_host_and_request_path("example.com", "/fuzz/bizz").should be_nil
      end
    end

    describe "when a service matches requested path but it is disabled" do
      before do
        expect(redis).to receive(:hget).with("brown-dispatcher-services:/foo", "enabled").and_return("false")
        expect(redis).to receive(:hget).with("brown-dispatcher-services:/baz", "enabled").and_return("true")
        expect(redis).to receive(:hget).with("brown-dispatcher-services:/baz", "hostname").and_return("foo.biz")
      end

      it "should return new Service with appropiate hostname" do
        BrownDispatcher::Service.find_for_http_host_and_request_path("example.com", "/fuzz/bizz").should be_nil
      end
    end

    describe "when a service matches requested path and it is enabled" do
      before do
        expect(redis).to receive(:hget).with("brown-dispatcher-services:/foo", "enabled").and_return("true")
        expect(redis).to receive(:hget).with("brown-dispatcher-services:/foo", "hostname").and_return("foo.biz")
      end

      it "should return new Service with appropiate hostname" do
        expect(redis).to receive(:hget).with("brown-dispatcher-services:/foo", "hostname").and_return("http://foobar.io")
        BrownDispatcher::Service.find_for_http_host_and_request_path("example.com", "/foo/bar").hostname.should == "http://foobar.io"
      end
    end
  end

  describe "#register" do
    it "should store all the prefixes in redis" do
      %w[/foo /bar].each do |prefix|
        expect(redis).to receive(:hset).with("brown-dispatcher-services:#{prefix}", "hostname", "http://foobar.io")
        expect(redis).to receive(:hset).with("brown-dispatcher-services:#{prefix}", "enabled", true)
      end
      BrownDispatcher::Service.register("http://foobar.io", "/foo", "/bar")
    end
  end
end
