class SearchesController < ApplicationController
  def show
    result_set = DiscoveryEngine::Search.new.call(
      query_params[:q],
      start: query_params[:start]&.to_i,
      count: query_params[:count]&.to_i,
    )

    render json: result_set
  end

private

  def query_params
    params.permit(:q, :start, :count)
  end
end
