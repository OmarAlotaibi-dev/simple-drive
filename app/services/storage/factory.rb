
module Storage
  class Factory
    def self.build(backend = ENV.fetch("STORAGE_BACKEND", "local"))
      case backend
      when "local"
        Storage::Local.new(
          directory: ENV.fetch(
            "STORAGE_DIR",
            Rails.root.join("storage", "blobs").to_s
          )
        )

      when "database"
        Storage::Database.new

      when "s3"
        Storage::S3.new(
          endpoint: ENV.fetch("S3_ENDPOINT"),
          bucket: ENV.fetch("S3_BUCKET"),
          region: ENV.fetch("S3_REGION"),
          access_key: ENV.fetch("S3_ACCESS_KEY"),
          secret_key: ENV.fetch("S3_SECRET_KEY")
        )

      when "ftp"
  Storage::Ftp.new(
    host: ENV.fetch("FTP_HOST"),
    username: ENV.fetch("FTP_USERNAME"),
    password: ENV.fetch("FTP_PASSWORD"),
    port: Integer(ENV.fetch("FTP_PORT", "21")),
    directory: ENV.fetch("FTP_DIRECTORY", "/")
  )

      else
        raise ArgumentError, "Unsupported storage backend: #{backend}"
      end
    end
  end
end
