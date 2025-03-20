module SchemaHelpers
  # TODO: This is the best option out of a bad bunch right now as this schema lives in a different
  # repository. Maybe eventually we will vendor the schema, or get it directly from the GCP API
  # client?
  METADATA_JSON_SCHEMA_URI = URI.parse(
    "https://raw.githubusercontent.com/alphagov/govuk-infrastructure/refs/heads/main/terraform/deployments/search-api-v2/files/datastore-schema.json",
  )

  # Returns a JSONSchemer object representing the JSON schema for document metadata
  def metadata_json_schema
    @@metadata_json_schema ||= begin # rubocop:disable Style/ClassVars
      remote_schema = Net::HTTP.get(METADATA_JSON_SCHEMA_URI)
      schema_contents = JSON.parse(remote_schema)

      JSONSchemer.schema(schema_contents)
    end
  end
end
