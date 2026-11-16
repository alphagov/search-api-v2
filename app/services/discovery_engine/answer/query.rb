module DiscoveryEngine::Answer
  class Query
    def initialize(question)
      @question = question
    end

    def response
      @response ||= DiscoveryEngine::Clients.conversational_search_service.answer_query(
        serving_config: ServingConfig.default.name,
        query: { text: question },
      )
    end

    def answer_text
      response.answer&.answer_text.to_s
    end

    def citations
      return [] unless response.answer

      references = response.answer.references
      cited_ids = response.answer.citations.flat_map { |c| c.sources.map(&:reference_id) }

      cited_ids.filter_map { |id| reference_location(references[id.to_i]) }.uniq
    end

  private

    attr_reader :question

    def reference_location(reference)
      return unless reference
      return reference.chunk_info.document_metadata&.uri.presence if reference.chunk_info

      document = reference.unstructured_document_info
      return document.uri.presence || document.title.presence if document

      reference.structured_document_info&.uri.presence
    end
  end
end
