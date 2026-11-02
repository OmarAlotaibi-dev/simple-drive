
require "net/http"
require "uri"
require "openssl"
require "digest"
require "time"

module Storage
  class S3
    def initialize(endpoint:, bucket:, region:, access_key:, secret_key:)
      @endpoint = URI(endpoint)
      @bucket = bucket
      @region = region
      @access_key = access_key
      @secret_key = secret_key
    end

    def write(id, data)
      request("PUT", id, data)
    end

    def read(id)
      request("GET", id)
    end

    private

    def request(method, id, data = "")
      uri = object_uri(id)
      timestamp = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      date = timestamp[0, 8]

      payload_hash = Digest::SHA256.hexdigest(data)
      host = uri.host
      host += ":#{uri.port}" unless uri.default_port == uri.port

      canonical_headers =
        "host:#{host}\n" \
        "x-amz-content-sha256:#{payload_hash}\n" \
        "x-amz-date:#{timestamp}\n"

      signed_headers = "host;x-amz-content-sha256;x-amz-date"

      canonical_request = [
        method,
        uri.path,
        "",
        canonical_headers,
        signed_headers,
        payload_hash
      ].join("\n")

      scope = "#{date}/#{@region}/s3/aws4_request"

      string_to_sign = [
        "AWS4-HMAC-SHA256",
        timestamp,
        scope,
        Digest::SHA256.hexdigest(canonical_request)
      ].join("\n")

      signing_key = signature_key(date)

      signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        signing_key,
        string_to_sign
      )

      authorization =
        "AWS4-HMAC-SHA256 Credential=#{@access_key}/#{scope}, " \
        "SignedHeaders=#{signed_headers}, Signature=#{signature}"

      http_request =
        method == "PUT" ? Net::HTTP::Put.new(uri) : Net::HTTP::Get.new(uri)

      http_request["Host"] = host
      http_request["x-amz-date"] = timestamp
      http_request["x-amz-content-sha256"] = payload_hash
      http_request["Authorization"] = authorization

      http_request.body = data if method == "PUT"

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https"
      ) do |http|
        http.request(http_request)
      end

 unless response.is_a?(Net::HTTPSuccess)
  raise "S3 request failed: HTTP #{response.code} - #{response.body}"
 end

      response.body
    end

    def object_uri(id)
      encoded_id = id.b.bytes.map do |byte|
  if byte.between?(65, 90) || byte.between?(97, 122) ||
   byte.between?(48, 57) || [ 45, 46, 47, 95, 126 ].include?(byte)
          byte.chr
  else
          "%%%02X" % byte
  end
      end.join

      uri = @endpoint.dup
      base_path = uri.path.sub(%r{/\z}, "")
      uri.path = "#{base_path}/#{@bucket}/#{encoded_id}"
      uri
    end

    def signature_key(date)
      key = OpenSSL::HMAC.digest(
        "SHA256", "AWS4#{@secret_key}", date
      )
      key = OpenSSL::HMAC.digest("SHA256", key, @region)
      key = OpenSSL::HMAC.digest("SHA256", key, "s3")
      OpenSSL::HMAC.digest("SHA256", key, "aws4_request")
    end
  end
end
