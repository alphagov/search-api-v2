module SchemaHelpers
  # TODO: This is the best option out of a bad bunch right now as this schema lives in a different
  # repository. Maybe eventually we will vendor the schema, or get it directly from the GCP API
  # client?
  METADATA_JSON_SCHEMA_URI = URI.parse(
    "https://raw.githubusercontent.com/alphagov/search-v2-infrastructure/main/terraform/modules/google_discovery_engine_restapi/files/datastore_schema.json",
  )

  # Returns a JSONSchemer object representing the JSON schema for document metadata
  def metadata_json_schema
    @metadata_json_schema ||= begin
      remote_schema = Net::HTTP.get(METADATA_JSON_SCHEMA_URI)
      schema_contents = JSON.parse(remote_schema)

      JSONSchemer.schema(schema_contents)
    end
  end
end
