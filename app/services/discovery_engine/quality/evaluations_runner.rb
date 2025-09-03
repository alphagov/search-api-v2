module DiscoveryEngine::Quality
  class EvaluationsRunner
    def initialize(table_id)
      @table_id = table_id
    end

    def upload_detailed_metrics
      true
    end

  private

    attr_reader :table_id
  end
end
