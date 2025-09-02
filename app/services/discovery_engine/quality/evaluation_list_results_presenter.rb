module DiscoveryEngine::Quality
  class EvaluationListResultsPresenter
    def initialize(json_response)
      @json_response = json_response
    end

    attr_reader :json_response

    def formatted_for_biq_query
      parsed = JSON.parse(json_response)
      clean = remove_empty_hashes(parsed)
      new_line_deliminate(clean)
    end

  private

    def remove_empty_hashes(obj)
      if obj.is_a?(Hash)
        obj.each do |k, v|
          obj[k] = remove_empty_hashes(v)
        end
        obj.reject { |_k, v| v == {} }
      elsif obj.is_a?(Array)
        obj.map { |o| remove_empty_hashes(o) }
      else
        obj
      end
    end

    def new_line_deliminate(json)
      json.map { |response| response.to_json }.join("\n")
    end
  end
end
