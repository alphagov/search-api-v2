module DiscoveryEngine
  module Quality::SampleQuerySetFields
    BIGQUERY_DATASET_ID = "automated_evaluation_input".freeze
    BIGQUERY_TABLE_ID = "clickstream".freeze

  module_function

    def display_name(month_interval)
      "#{BIGQUERY_TABLE_ID} #{month_interval}"
    end

    def description(month_interval)
      "Generated from #{month_interval} BigQuery #{BIGQUERY_TABLE_ID} data"
    end

    def sample_query_set_id(month_interval)
      "#{BIGQUERY_TABLE_ID}_#{month_interval}"
    end
  end
end
