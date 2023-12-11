module DiscoveryEngine::Query::FilterExpressions
  class StringValue
    def initialize(raw_string)
      @raw_string = raw_string
    end

    def to_s
      "\"#{escaped_string}\""
    end

  private

    attr_reader :raw_string

    def escaped_string
      raw_string.gsub(/(["\\])/, '\\\\\1')
    end
  end
end
