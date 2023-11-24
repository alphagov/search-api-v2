RSpec.describe PublishingApi::Content do
  subject(:concern_consumer) { Struct.new(:document_hash).include(described_class) }

  describe "#content" do
    subject(:extracted_content) { concern_consumer.new(document_hash).content }

    describe "with basic top-level fields" do
      let(:document_hash) do
        {
          details: {
            body: "a",
            description: "b",
            introduction: "c",
            introductory_paragraph: "d",
            more_information: "e",
            need_to_know: "f",
            summary: "g",
            title: "h",
          },
        }
      end

      it { is_expected.to eq("a\nb\nc\nd\ne\nf\ng\nh") }
    end

    describe "with contact groups" do
      let(:document_hash) do
        {
          details: {
            contact_groups: [
              { title: "x" },
              { title: "y" },
              { title: "z" },
            ],
          },
        }
      end

      it { is_expected.to eq("x\ny\nz") }
    end

    describe "with parts" do
      let(:document_hash) do
        {
          details: {
            parts: [
              {
                title: "Foo",
                slug: "/foo",
                body: [
                  {
                    content: "bar",
                    content_type: "text/html",
                  },
                ],
              },
              {
                title: "Bar",
                slug: "/bar",
                body: [
                  {
                    content: "<blink>baz</blink>",
                    content_type: "text/html",
                  },
                ],
              },
            ],
          },
        }
      end

      it { is_expected.to eq("<h1>Foo</h1>\nbar\n<h1>Bar</h1>\n<blink>baz</blink>") }
    end

    describe "with excessively large content" do
      let(:document_hash) do
        {
          details: {
            body: "a" * 600.kilobytes,
          },
        }
      end

      it "truncates the content" do
        expect(extracted_content.bytesize).to be <= 500.kilobytes
      end
    end

    describe "without any fields" do
      let(:document_hash) do
        {
          details: {},
        }
      end

      it { is_expected.to be_blank }
    end
  end
end
