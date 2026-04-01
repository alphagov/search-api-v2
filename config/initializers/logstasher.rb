if ENV["GOVUK_RAILS_JSON_LOGGING"].present?
  ActiveSupport::Notifications.subscribe("vertex_search_request_duration") do |event|
    duration_in_seconds = event.duration / 1000.0

    GovukJsonLogging.configure do
      add_custom_fields do |fields|
        fields[:vertex_search_duration] = duration_in_seconds
      end
    end
  end
end
