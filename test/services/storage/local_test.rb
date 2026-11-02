
require "test_helper"
require "tmpdir"

class Storage::LocalTest < ActiveSupport::TestCase
  test "writes and reads binary data" do
    Dir.mktmpdir do |directory|
      storage = Storage::Local.new(directory: directory)
      binary = [0, 1, 127, 128, 255].pack("C*")

      storage.write("local-binary-test", binary)

      assert_equal binary, storage.read("local-binary-test")
    end
  end

  test "supports IDs containing slashes" do
    Dir.mktmpdir do |directory|
      storage = Storage::Local.new(directory: directory)

      storage.write("folder/subfolder/file.txt", "Hello Local")

      assert_equal "Hello Local",
                   storage.read("folder/subfolder/file.txt")
    end
  end
end
