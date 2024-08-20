class AutocompletesController < ApplicationController
  def show
    render json: DiscoveryEngine::Autocomplete::Complete.new(query).completion_result
  end

private

  def query
    params[:q]
  end
end
