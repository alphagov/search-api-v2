class SearchesController < ApplicationController
  before_action :validate_query_params, only: :show
  after_action :add_response_time_header

  def show
    with_duration_logging do
      @search_results = DiscoveryEngine::Query::Search.new(query_params, user_agent: request.user_agent).result_set
    end
    render json: @search_results
  end

private

  def query_params
    params.permit!
  end

  def validate_query_params
    raise ActionController::BadRequest, "Invalid query parameter" unless params.fetch(:q, "").is_a?(String)
  end

  def with_duration_logging(&block)
    @duration = Benchmark.realtime(&block)
  end

  def add_response_time_header
    return unless @duration

    response.headers["Vertex-Response-Time"] = @duration.round(4).to_s
  end
end
