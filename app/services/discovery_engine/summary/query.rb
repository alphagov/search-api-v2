module DiscoveryEngine::Summary
  class Query
    NUMBER_OF_RESULTS = 5
    def initialize(question)
      @question = question
    end

    def response
      @response ||= DiscoveryEngine::Clients.search_service.search(
        {
          serving_config: ServingConfig.default.name,
          query: question,
          page_size: NUMBER_OF_RESULTS,
          content_search_spec: {
            summary_spec: { summary_result_count: NUMBER_OF_RESULTS,
                            include_citations: true,
                            use_semantic_chunks: true },
            extractive_content_spec: { max_extractive_answer_count: 1 },
          },
        },
        timeout: 60,
      ).response
    end

    def summary_text
      response.summary&.summary_text.to_s
    end

    def extractive_answers
      response.results.flat_map do |result|
        data = result.document&.derived_struct_data&.to_h
        answers = Array(data&.fetch("extractive_answers", nil)).filter_map { |answer| answer["content"].presence }
        answers.map { |answer| CGI.unescapeHTML(answer) }
      end
    end

    def citations
      metadata = response.summary&.summary_with_metadata
      return [] unless metadata

      metadata.references.filter_map { |reference| reference.uri.presence }.uniq
    end

  private

    attr_reader :question
  end
end
