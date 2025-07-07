module DiscoveryEngine
  module Quality
    class SampleQuerySets
      BIGQUERY_TABLE_IDS = %w[binary clickstream explicit].freeze

      attr_reader :month_interval, :sets

      def initialize(month_interval)
        @month_interval = month_interval
      end

      def sets
        @sets ||= BIGQUERY_TABLE_IDS.map do |table_id|
          SampleQuerySet.new(month_interval, table_id)
        end
      end
    end
  end
end
