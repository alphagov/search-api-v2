module PublishingApi
  class BodyContent
    def initialize(raw_content)
      @content = case raw_content
                 in String
                   raw_content
                 in [*, { content_type: "text/html", content: html_content }, *]
                   html_content
                 in Array
                   raw_content.join(" ") if raw_content.all? { _1.is_a?(String) }
                 else
                   nil
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
