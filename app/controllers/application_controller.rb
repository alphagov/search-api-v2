class ApplicationController < ActionController::API
private

  def render_internal_error
    render json: { "error": "Internal server error" }, status: :internal_server_error
  end
end
