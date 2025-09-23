class SearchesController < ApplicationController
  before_action :validate_query_params, only: :show

  def show
    render json: DiscoveryEngine::Query::Search.new(query_params, user_agent: request.user_agent).result_set
  end

private

  def query_params
    params.permit!
  end

  def validate_query_params
    raise ActionController::BadRequest, "Invalid query parameter" unless params.fetch(:q, "").is_a?(String)
  end
end
