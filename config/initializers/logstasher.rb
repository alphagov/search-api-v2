if ENV["GOVUK_RAILS_JSON_LOGGING"].present?
  ActiveSupport::Notifications.subscribe("vertex_request") do
    GovukJsonLogging.configure do
      add_custom_fields do |fields|
        fields[:vertex_request_duration] = event.duration
      end
    end
  end
end