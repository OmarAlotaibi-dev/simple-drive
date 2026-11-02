
require "test_helper"
require "net/http"

class Storage::S3Test < ActiveSupport::TestCase
  setup do
    @storage = Storage::S3.new(
      endpoint: "http://127.0.0.1:9000",
      bucket: "simple-drive",
      region: "us-east-1",
      access_key: "test-access-key",
      secret_key: "test-secret-key"
    )
  end

  test "builds S3 storage with configured credentials" do
    assert_instance_of Storage::S3, @storage
  end

  test "writes and reads binary data through HTTP" do
    binary = [0, 1, 127, 128, 255].pack("C*")
    requests = []

    fake_http = Object.new

    fake_http.define_singleton_method(:request) do |request|
      requests << request

response = Net::HTTPOK.new("1.1", "200", "OK")

response.instance_variable_set(:@read, true)

response.body = if request.is_a?(Net::HTTP::Put)
  ""
else
  binary
end

response
    end

    original_start = Net::HTTP.method(:start)

    Net::HTTP.define_singleton_method(:start) do |*args, **kwargs, &block|
      block.call(fake_http)
    end

    begin
      @storage.write("binary-test", binary)
      result = @storage.read("binary-test")

      assert_equal binary, result
      assert_equal 2, requests.length
      assert_instance_of Net::HTTP::Put, requests.first
      assert_instance_of Net::HTTP::Get, requests.last
    ensure
      Net::HTTP.define_singleton_method(:start, original_start)
    end
  end
end
