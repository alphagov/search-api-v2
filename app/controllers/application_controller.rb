class ApplicationController < ActionController::API
  rescue_from DiscoveryEngine::InternalError, with: :render_internal_error
  rescue_from ActionController::BadRequest, with: :render_bad_request

private

  def render_internal_error
    render json: { "error": "Internal server error" }, status: :internal_server_error
  end

  def render_bad_request(exception)
    render json: { "error": exception.message }, status: :bad_request
  end
end
