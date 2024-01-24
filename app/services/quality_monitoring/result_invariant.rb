module QualityMonitoring
  # Represents a query and the links that should always be returned on the first page of results
  ResultInvariant = Data.define(:query, :expected_links) do
    def self.all
      config_values = Rails.application.config.result_invariants || {}

      config_values.map do |query, expected_link_or_links|
        new(query: query.to_s, expected_links: Array(expected_link_or_links))
      end
    end
  end
end
