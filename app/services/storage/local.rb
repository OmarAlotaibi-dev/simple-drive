require "fileutils"
require "digest"

module Storage
  class Local
    def initialize(directory:)
      @directory = directory
      FileUtils.mkdir_p(@directory)
    end

    def write(id, data)
      File.binwrite(path_for(id), data)
    end

    def read(id)
      File.binread(path_for(id))
    end

    private

    def path_for(id)
      filename = Digest::SHA256.hexdigest(id)
      File.join(@directory, filename)
    end
  end
end
