class ApplicationController < ActionController::API
  before_action :authenticate_request!

  private

  def authenticate_request!
    expected_token = ENV["API_TOKEN"]
    provided_token = request.authorization.to_s

    unless expected_token.present? &&
           ActiveSupport::SecurityUtils.secure_compare(
             provided_token,
             "Bearer #{expected_token}"
           )
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
