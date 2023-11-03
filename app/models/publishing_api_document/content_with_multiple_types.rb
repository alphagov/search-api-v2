module PublishingApiDocument
  class ContentWithMultipleTypes
    def initialize(content_with_multiple_types)
      @content_with_multiple_types = content_with_multiple_types
    end

    def html_content
      @content_with_multiple_types.find { _1[:content_type] == "text/html" }&.dig(:content)
    end

    def text_content
      Loofah
        .document(html_content)
        .to_text(encode_special_chars: false)
        .squish
    end

    def summarized_text_content(length: 75, omission: "…", separator: " ")
      text_content.truncate(length, omission:, separator:)
    end
  end
end
