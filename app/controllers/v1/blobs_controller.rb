
require "base64"
require "net/http"

module V1
  class BlobsController < ApplicationController
    rescue_from Errno::ECONNREFUSED,
                Errno::EHOSTUNREACH,
                Net::OpenTimeout,
                Net::ReadTimeout,
                with: :storage_unavailable

    def create
      blob_id = params[:id]
      encoded_data = params[:data]

      unless blob_id.is_a?(String) && blob_id.present? &&
             encoded_data.is_a?(String)
        return render json: { error: "Invalid id or data" },
                      status: :bad_request
      end

      begin
        binary_data = Base64.strict_decode64(encoded_data)
      rescue ArgumentError
        return render json: { error: "Invalid Base64 data" },
                      status: :bad_request
      end

      if BlobMetadatum.exists?(blob_id: blob_id)
        return render json: { error: "Blob already exists" },
                      status: :conflict
      end

      backend = ENV.fetch("STORAGE_BACKEND", "local")
      storage = Storage::Factory.build(backend)

      storage.write(blob_id, binary_data)

      metadata = BlobMetadatum.create!(
        blob_id: blob_id,
        size_bytes: binary_data.bytesize,
        storage_backend: backend
      )

      render json: {
        id: metadata.blob_id,
        size: metadata.size_bytes.to_s,
        created_at: metadata.created_at.utc.iso8601
      }, status: :created
    end

    def show
      metadata = BlobMetadatum.find_by(blob_id: params[:id])

      unless metadata
        return render json: { error: "Blob not found" },
                      status: :not_found
      end

      storage = Storage::Factory.build(metadata.storage_backend)
      binary_data = storage.read(metadata.blob_id)

      render json: {
        id: metadata.blob_id,
        data: Base64.strict_encode64(binary_data),
        size: metadata.size_bytes.to_s,
        created_at: metadata.created_at.utc.iso8601
      }, status: :ok
    end

    private

    def storage_unavailable(exception)
      Rails.logger.error("Storage connection failed: #{exception.class}")
      render json: { error: "Storage unavailable" },
             status: :service_unavailable
    end
  end
end
