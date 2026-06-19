class ApplicationController < ActionController::API
  rescue_from ActionController::BadRequest, with: :render_bad_request

private

  def render_bad_request(exception)
    render json: { "error": exception.message }, status: :bad_request
  end
end
