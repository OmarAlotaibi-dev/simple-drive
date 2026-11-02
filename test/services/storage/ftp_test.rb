
require "test_helper"
require "net/ftp"

class Storage::FtpTest < ActiveSupport::TestCase
  test "builds FTP storage with configured credentials" do
    storage = Storage::Ftp.new(
      host: "127.0.0.1",
      username: "test-user",
      password: "test-password",
      port: 2121,
      directory: "/"
    )

    assert_instance_of Storage::Ftp, storage
  end

  test "writes and reads binary data through FTP" do
    storage = Storage::Ftp.new(
      host: "127.0.0.1",
      username: "test-user",
      password: "test-password",
      port: 2121,
      directory: "/"
    )

    binary = [0, 1, 127, 128, 255].pack("C*")
    uploaded = nil

    fake_ftp = Object.new

    fake_ftp.define_singleton_method(:connect) { |*args| }
    fake_ftp.define_singleton_method(:login) { |*args| }
    fake_ftp.define_singleton_method(:passive=) { |value| }
    fake_ftp.define_singleton_method(:chdir) { |directory| }
    fake_ftp.define_singleton_method(:closed?) { false }
    fake_ftp.define_singleton_method(:close) { }

    fake_ftp.define_singleton_method(:storbinary) do |command, io, blocksize|
      uploaded = io.read
    end

    fake_ftp.define_singleton_method(:retrbinary) do |command, blocksize, &block|
      block.call(uploaded)
    end

    original_new = Net::FTP.method(:new)

    Net::FTP.define_singleton_method(:new) do |*args|
      fake_ftp
    end

    begin
      storage.write("ftp-binary-test", binary)
      result = storage.read("ftp-binary-test")

      assert_equal binary, result
    ensure
      Net::FTP.define_singleton_method(:new, original_new)
    end
  end
end
