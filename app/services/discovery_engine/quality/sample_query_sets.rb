module DiscoveryEngine
  module Quality
    class SampleQuerySets
      BIGQUERY_TABLE_IDS = %w[clickstream].freeze

      attr_reader :month_interval

      def initialize(month_interval)
        @month_interval = month_interval
      end

      def all
        @all ||= BIGQUERY_TABLE_IDS.map do |table_id|
          SampleQuerySet.new(month_interval, table_id)
        end
      end
    end
  end
end
