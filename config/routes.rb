Rails.application.routes.draw do
  resource :search, only: [:show]
  resource :autocomplete, only: [:show]

  # Healthchecks
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response
end
