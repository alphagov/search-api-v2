module DiscoveryEngine
  module Quality
    class SampleQuerySets
      BIGQUERY_TABLE_IDS = %w[clickstream].freeze

      attr_reader :month_label

      def initialize(month_label)
        @month_label = month_label
      end

      def all
        @all ||= BIGQUERY_TABLE_IDS.map do |table_id|
          SampleQuerySet.new(table_id:, month_label:)
        end
      end

      def create_and_import_all
        all.each(&:create_and_import)
      end
    end
  end
end
