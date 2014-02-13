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
      redis.hset "brown-dispatcher-services:/bar", "enabled", "true"
      redis.hset "brown-dispatcher-services:/bar", "hostname", "foo.biz"
      redis.hset "brown-dispatcher-services:/foo", "enabled", "false"
      redis.hset "brown-dispatcher-services:/baz", "enabled", "false"
    end

    describe "when no service matches requested path" do
      before do
        redis.hset "brown-dispatcher-services:/foo", "enabled", "true"
        redis.hset "brown-dispatcher-services:/foo", "hostname", "foo.biz"
        redis.hset "brown-dispatcher-services:/baz", "enabled", "true"
        redis.hset "brown-dispatcher-services:/baz", "hostname", "foo.biz"
      end

      it "should return nil" do
        BrownDispatcher::Service.find_for_http_host_and_request_path("example.com", "/fuzz/bizz").should be_nil
      end
    end

    describe "when a service matches requested path but it is disabled" do
      before do
        redis.hset "brown-dispatcher-services:/foo", "enabled", "false"
        redis.hset "brown-dispatcher-services:/baz", "enabled", "true"
        redis.hset "brown-dispatcher-services:/baz", "hostname", "foo.biz"
      end

      it "should return nil" do
        BrownDispatcher::Service.find_for_http_host_and_request_path("example.com", "/fuzz/bizz").should be_nil
      end
    end

    describe "when a service matches requested path and it is enabled" do
      before do
        redis.hset "brown-dispatcher-services:/foo", "enabled", "true"
        redis.hset "brown-dispatcher-services:/foo", "hostname", "foo.biz"
      end

      it "should return new Service with appropiate hostname" do
        redis.hset "brown-dispatcher-services:/foo", "hostname", "http://foobar.io"
        BrownDispatcher::Service.find_for_http_host_and_request_path("example.com", "/foo/bar").hostname.should == "http://foobar.io"
      end
    end
  end

  describe "#register" do
    it "should store all the prefixes in redis" do
      %w[/foo /bar].each do |prefix|
        redis.hget("brown-dispatcher-services:#{prefix}", "enabled").should be_nil
        redis.hget("brown-dispatcher-services:#{prefix}", "hostname").should be_nil
      end
      %w[/foo /bar].each do |prefix|
        redis.hset "brown-dispatcher-services:#{prefix}", "hostname", "http://foobar.io"
        redis.hset "brown-dispatcher-services:#{prefix}", "enabled", "true"
      end
      BrownDispatcher::Service.register("http://foobar.io", "/foo", "/bar")
      %w[/foo /bar].each do |prefix|
        redis.hget("brown-dispatcher-services:#{prefix}", "enabled").should == "true"
        redis.hget("brown-dispatcher-services:#{prefix}", "hostname").should == "http://foobar.io"
      end
    end
  end
end
