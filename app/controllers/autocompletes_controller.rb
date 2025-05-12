class AutocompletesController < ApplicationController
  rescue_from DiscoveryEngine::InternalError, with: :render_internal_error

  def show
    render json: completion_result
  end

private

  def completion_result
    return CompletionResult.new(suggestions: []) unless Rails.configuration.enable_autocomplete

    DiscoveryEngine::Autocomplete::Complete.new(query).completion_result
  end

  def query
    params[:q]
  end
end
