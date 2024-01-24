module QualityMonitoring
  # Represents a missing result link for a query
  ResultInvariantViolation = Data.define(:query, :expected_link)
end
