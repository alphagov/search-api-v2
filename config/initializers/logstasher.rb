if ENV["GOVUK_RAILS_JSON_LOGGING"].present?
  GovukJsonLogging.configure do
    add_custom_fields do |fields|
      fields[:vertex_search_duration] = response.headers["Vertex-Response-Time"]
    end
  end
end
