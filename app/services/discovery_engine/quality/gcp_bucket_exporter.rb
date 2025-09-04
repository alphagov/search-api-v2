module DiscoveryEngine::Quality
  class GcpBucketExporter
    PROJECT_NAME = "search-api-v2-integration".freeze # replace with an env var

    def send(data)
      bucket = storage_client.bucket("#{PROJECT_NAME}_vais_evaluation_output")
      bucket.create_file(StringIO.new(data), file_name)
    end

  private

    def file_name
      "filename"
    end

    def storage_client
      DiscoveryEngine::Clients.cloud_storage_service.new(project: PROJECT_NAME)
    end
  end
end
