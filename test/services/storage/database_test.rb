
require "test_helper"

class Storage::DatabaseTest < ActiveSupport::TestCase
  test "writes and reads binary data" do
    storage = Storage::Database.new
    binary = [0, 1, 127, 128, 255].pack("C*")

    storage.write("database-binary-test", binary)

    assert_equal binary, storage.read("database-binary-test")
  end

  test "supports IDs containing slashes" do
    storage = Storage::Database.new

    storage.write("folder/subfolder/file.txt", "Hello Database")

    assert_equal "Hello Database",
                 storage.read("folder/subfolder/file.txt")
  end
end
