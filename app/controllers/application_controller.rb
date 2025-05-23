class ApplicationController < ActionController::API
  rescue_from DiscoveryEngine::InternalError, with: :render_internal_error

private

  def render_internal_error
    render json: { "error": "Internal server error" }, status: :internal_server_error
  end
end
