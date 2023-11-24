RSpec.describe PublishingApi::BodyContent do
  subject(:body_content) { described_class.new(content) }

  context "when the content is a plain string" do
    let(:content) { "Hello, world!" }

    describe "#html_content" do
      subject(:html_content) { body_content.html_content }

      it { is_expected.to eq("Hello, world!") }
    end

    describe "#text_content" do
      subject(:text_content) { body_content.text_content }

      it { is_expected.to eq("Hello, world!") }
    end

    describe "#summarized_text_content" do
      subject(:summarized_text_content) { body_content.summarized_text_content(length: 6) }

      it { is_expected.to eq("Hello…") }
    end
  end

  context "when the content is an array of typed content that includes text/html content" do
    let(:content) do
      [
        { content_type: "application/json", content: '{"foo": "bar"}' },
        { content_type: "text/html", content: "<blink>Hello, world!</blink>" },
      ]
    end

    describe "#html_content" do
      subject(:html_content) { body_content.html_content }

      it { is_expected.to eq("<blink>Hello, world!</blink>") }
    end

    describe "#text_content" do
      subject(:text_content) { body_content.text_content }

      it { is_expected.to eq("Hello, world!") }
    end

    describe "#summarized_text_content" do
      subject(:summarized_text_content) { body_content.summarized_text_content(length: 6) }

      it { is_expected.to eq("Hello…") }
    end
  end

  context "when the content is an array of typed content that doesn't include text/html content" do
    let(:content) do
      [
        { content_type: "application/json", content: '{"foo": "bar"}' },
      ]
    end

    describe "#html_content" do
      subject(:html_content) { body_content.html_content }

      it { is_expected.to be_nil }
    end

    describe "#text_content" do
      subject(:text_content) { body_content.text_content }

      it { is_expected.to be_nil }
    end

    describe "#summarized_text_content" do
      subject(:summarized_text_content) { body_content.summarized_text_content }

      it { is_expected.to be_nil }
    end
  end
end
