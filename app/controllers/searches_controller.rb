class SearchesController < ApplicationController
  rescue_from DiscoveryEngine::InternalError, with: :render_internal_error

  def show
    render json: DiscoveryEngine::Query::Search.new(query_params).result_set
  end

private

  def query_params
    params.permit!
  end
end
