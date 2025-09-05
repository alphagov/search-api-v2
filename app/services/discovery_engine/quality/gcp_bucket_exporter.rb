module DiscoveryEngine::Quality
  class GcpBucketExporter
    PROJECT_NAME = "search-api-v2-integration".freeze # replace with an env var

    def send(time_stamp, table_id, partition_date, json)
      bucket = storage_client.bucket "#{PROJECT_NAME}_vais_evaluation_output"
      bucket.create_file StringIO.new(json), file_name(time_stamp, table_id, partition_date)
    end

    def file_name(time_stamp, table_id, partition_date)
      "judgement_list=#{table_id}/partition_date=#{partition_date}/create_time=#{time_stamp}/results.json"
    end

  private

    def storage_client
      DiscoveryEngine::Clients.cloud_storage_service.new(project: PROJECT_NAME)
    end
  end
end
