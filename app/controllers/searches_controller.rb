class SearchesController < ApplicationController
  rescue_from ArgumentError, with: :render_argument_error

  def show
    render json: DiscoveryEngine::Query::Search.new(query_params, user_agent: request.user_agent).result_set
  end

private

  def query_params
    params.permit!
  end

  def render_argument_error(exception)
    render json: { "error": exception.message }, status: :unprocessable_content
  end
end
