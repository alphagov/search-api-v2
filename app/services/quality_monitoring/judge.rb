module QualityMonitoring
  class Judge
    attr_reader :result_links, :expected_links

    # Initializes a new instance of Judge for a given set of result links and expected links
    def initialize(result_links, expected_links)
      @result_links = Array(result_links)
      @expected_links = Array(expected_links)

      raise ArgumentError, "at least one expected link is required" if expected_links.empty?
    end

    # Calculates recall (how many of the expected links are in the result links)
    def recall
      expected_links.count { result_links.include?(_1) }.to_f / expected_links.count
    end

    # Calculates precision (how many of the result links are in the expected links)
    def precision
      return 0 if result_links.empty?

      result_links.count { expected_links.include?(_1) }.to_f / result_links.count
    end
  end
end
