require "spec_helper"

describe BrownDispatcher::Service do
  before do
    redis_current = double
    allow(Redis).to receive(:current).and_return(redis_current)
  end

  describe "#find_for_request_path" do
    before { expect(Redis.current).to receive(:hkeys).with("brown-dispatcher-services").and_return(%w[/foo]) }

    describe "when no service matches requested path" do
      it "should return nil" do
        BrownDispatcher::Service.find_for_request_path("/fuzz/bizz").should be_nil
      end
    end

    describe "when a service matches requested path" do
      it "should return new Service with appropiate hostname" do
        expect(Redis.current).to receive(:hget).with("brown-dispatcher-services", "/foo").and_return("http://foobar.io")
        BrownDispatcher::Service.find_for_request_path("/foo/bar").hostname.should == "http://foobar.io"
      end
    end
  end

  describe "#register" do
    it "should store all the prefixes in redis" do
      %w[/foo /bar].each do |prefix|
        expect(Redis.current).to receive(:hset).with("brown-dispatcher-services", prefix, "http://foobar.io")
      end
      BrownDispatcher::Service.register("http://foobar.io", "/foo", "/bar")
    end
  end
end
