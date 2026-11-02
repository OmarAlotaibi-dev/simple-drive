require "test_helper"
require "base64"

class V1::BlobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token = "test-api-token"
    @headers = {
      "Authorization" => "Bearer #{@token}"
    }

    @previous_token = ENV["API_TOKEN"]
    @previous_backend = ENV["STORAGE_BACKEND"]

    ENV["API_TOKEN"] = @token
    ENV["STORAGE_BACKEND"] = "database"
  end

  teardown do
    ENV["API_TOKEN"] = @previous_token
    ENV["STORAGE_BACKEND"] = @previous_backend
  end

  test "rejects requests without a bearer token" do
    get "/v1/blobs/missing-id"

    assert_response :unauthorized
  end

  test "creates and retrieves a blob" do
    encoded = Base64.strict_encode64("Hello Simple Drive")

    post "/v1/blobs",
      params: { id: "test-blob-1", data: encoded },
      as: :json,
      headers: @headers

    assert_response :created

    get "/v1/blobs/test-blob-1", headers: @headers

    assert_response :success

    result = response.parsed_body

    assert_equal "test-blob-1", result["id"]
    assert_equal encoded, result["data"]
    assert_equal "18", result["size"]
    assert_match(/\A\d{4}-\d{2}-\d{2}T/, result["created_at"])
  end

  test "rejects invalid Base64" do
    post "/v1/blobs",
      params: { id: "invalid-test", data: "not-valid-@@@" },
      as: :json,
      headers: @headers

    assert_response :bad_request
  end

  test "rejects duplicate IDs" do
    encoded = Base64.strict_encode64("duplicate")

    2.times do
      post "/v1/blobs",
        params: { id: "duplicate-test", data: encoded },
        as: :json,
        headers: @headers
    end

    assert_response :conflict
  end

  test "returns 404 for a missing blob" do
    get "/v1/blobs/nonexistent-test-id", headers: @headers

    assert_response :not_found
  end

  test "preserves binary data" do
    binary = [0, 1, 127, 128, 255].pack("C*")
    encoded = Base64.strict_encode64(binary)

    post "/v1/blobs",
      params: { id: "binary-test", data: encoded },
      as: :json,
      headers: @headers

    assert_response :created

    get "/v1/blobs/binary-test", headers: @headers

    assert_response :success
    assert_equal binary, Base64.strict_decode64(response.parsed_body["data"])
  end

  test "supports IDs containing slashes" do
    encoded = Base64.strict_encode64("nested content")

    post "/v1/blobs",
      params: { id: "folder/subfolder/file.txt", data: encoded },
      as: :json,
      headers: @headers

    assert_response :created

    get "/v1/blobs/folder/subfolder/file.txt", headers: @headers

    assert_response :success
    assert_equal encoded, response.parsed_body["data"]
  end

  test "supports empty binary data" do
    post "/v1/blobs",
      params: { id: "empty-test", data: "" },
      as: :json,
      headers: @headers

    assert_response :created

    get "/v1/blobs/empty-test", headers: @headers

    assert_response :success
    assert_equal "", response.parsed_body["data"]
    assert_equal "0", response.parsed_body["size"]
  end
end