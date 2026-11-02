
require "net/ftp"
require "digest"
require "stringio"

module Storage
  class Ftp
    def initialize(host:, username:, password:, port: 21, directory: "/")
      @host = host
      @port = port
      @username = username
      @password = password
      @directory = directory
    end

    def write(id, data)
      with_connection do |ftp|
        filename = Digest::SHA256.hexdigest(id)
        ftp.storbinary("STOR #{filename}", StringIO.new(data), 8192)
      end
    end

    def read(id)
      with_connection do |ftp|
        filename = Digest::SHA256.hexdigest(id)
        result = +"".b

        ftp.retrbinary("RETR #{filename}", 8192) do |chunk|
          result << chunk
        end

        result
      end
    end

    private

    def with_connection
      ftp = Net::FTP.new
      ftp.connect(@host, @port)
      ftp.login(@username, @password)
      ftp.passive = true
      ftp.chdir(@directory)

      yield ftp
    ensure
      ftp&.close unless ftp&.closed?
    end
  end
end
