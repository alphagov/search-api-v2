module PublishingApi
  class BodyContent
    def initialize(raw_content)
      @content = case raw_content
                 when String
                   raw_content
                 when Array
                   raw_content.find { _1[:content_type] == "text/html" }&.dig(:content)
                 end
    end

    def html_content
      content
    end

    def text_content
      return nil unless html_content

      Loofah
        .document(html_content)
        .to_text(encode_special_chars: false)
        .squish
    end

    def summarized_text_content(length: 75, omission: "…", separator: " ")
      text_content&.truncate(length, omission:, separator:)
    end

  private

    attr_reader :content
  end
end
