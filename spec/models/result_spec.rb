RSpec.describe Result, type: :model do
  describe ".from_stored_document" do
    subject(:result) { described_class.from_stored_document(stored_document) }

    let(:stored_document) do
      {
        "content_id" => "12345",
        "title" => "Sample Title",
        "link" => "/sample-link",
        "content_purpose_supergroup" => "news_and_communications",
        "parts" => [],
        "part_of_taxonomy_tree" => [],
        "government_name" => "Sample Government",
        "public_timestamp" => 1_698_831_790, # 2023-11-01T09:43:10+00:00
        "description" => "Sample Description",
        "document_type" => "news_story",
        "is_historic" => 1,
      }
    end

    it "creates a new Result instance with the correct attributes" do
      expect(result).to have_attributes(
        content_id: "12345",
        title: "Sample Title",
        link: "/sample-link",
        content_purpose_supergroup: "news_and_communications",
        parts: [],
        part_of_taxonomy_tree: [],
        public_timestamp: "2023-11-01T09:43:10+00:00",
        government_name: "Sample Government",
        description_with_highlighting: "Sample Description",
        format: "news_story",
        content_store_document_type: "news_story",
        is_historic: true,
      )
    end

    context "when the document is external (link doesn't start with '/')" do
      let(:stored_document) { { "link" => "https://www.example.org", "content_id" => "12345" } }

      it "sets _id to the value of content_id" do
        expect(result._id).to eq("12345")
      end
    end

    context "when public_timestamp is nil" do
      let(:stored_document) { { "public_timestamp" => nil } }

      it "sets public_timestamp to nil" do
        expect(result.public_timestamp).to be_nil
      end
    end

    context "when is_historic is nil" do
      let(:stored_document) { { "is_historic" => nil } }

      it "sets is_historic to false" do
        expect(result.is_historic).to be(false)
      end
    end

    context "when is_historic is 1" do
      let(:stored_document) { { "is_historic" => 1 } }

      it "sets is_historic to true" do
        expect(result.is_historic).to be(true)
      end
    end

    context "when is_historic is not 1" do
      let(:stored_document) { { "is_historic" => 0 } }

      it "sets is_historic to false" do
        expect(result.is_historic).to be(false)
      end
    end

    context "when document data is missing or incomplete" do
      let(:stored_document) { {} }

      it "handles missing or incomplete data gracefully" do
        expect { result }.not_to raise_error
      end
    end
  end
end
