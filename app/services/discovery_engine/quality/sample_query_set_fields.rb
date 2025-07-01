module DiscoveryEngine
  module Quality::SampleQuerySetFields
    BIGQUERY_DATASET_ID = "automated_evaluation_input".freeze
    BIGQUERY_TABLE_ID = "clickstream".freeze

  module_function

    def display_name(date)
      "#{BIGQUERY_TABLE_ID} #{formatted_date(date)}"
    end

    def description(date)
      "Generated from #{formatted_date(date)} BigQuery #{BIGQUERY_TABLE_ID} data"
    end

    def sample_query_set_id(date)
      "#{BIGQUERY_TABLE_ID}_#{formatted_date(date)}"
    end

    def formatted_date(date)
      date.strftime("%Y-%m")
    end
  end
end
