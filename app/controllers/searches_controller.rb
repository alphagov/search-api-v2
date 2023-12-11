class SearchesController < ApplicationController
  def show
    render json: DiscoveryEngine::Query::Search.new(query_params).result_set
  end

private

  def query_params
    params.permit!
  end
end
