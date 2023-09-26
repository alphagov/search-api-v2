require "search_repositories/null/null_repository"

RSpec.describe SearchRepositories::Null::NullRepository do
  let(:repository) { described_class.new }
  let(:content_id) { "some_content_id" }
  let(:metadata) { { base_path: "/some/path" } }
  let(:content) { "Lorem ipsum dolor sit amet, consecutur edipiscing elit" }
  let(:payload_version) { "1" }

  describe "#put" do
    it "logs the put operation" do
      expect(Rails.logger).to receive(:info).with(
        a_string_ending_with(
          "Persisted some_content_id: /some/path (@v1): " \
          "'Lorem ipsum dolor sit amet, consecutur edipiscing e...'",
        ),
      )

      repository.put(content_id, metadata, content:, payload_version:)
    end
  end

  describe "#delete" do
    it "logs the delete operation" do
      expect(Rails.logger).to receive(:info).with(
        a_string_ending_with("Deleted some_content_id (@v1)"),
      )

      repository.delete(content_id, payload_version:)
    end
  end
end
