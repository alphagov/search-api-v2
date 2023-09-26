require "search_repositories/null/null_repository"

RSpec.describe SearchRepositories::Null::NullRepository do
  let(:repository) { described_class.new(logger:) }
  let(:logger) { instance_double(Logger, info: nil) }

  describe "#put" do
    it "logs the put operation" do
      repository.put(
        "some_content_id",
        { base_path: "/some/path" },
        content: "Lorem ipsum dolor sit amet, consecutur edipiscing elit",
        payload_version: "1",
      )

      expect(logger).to have_received(:info).with(
        "[PUT some_content_id@v1] /some/path: " \
          "'Lorem ipsum dolor sit amet, consecutur edipiscing e...'",
      )
    end
  end

  describe "#delete" do
    it "logs the delete operation" do
      repository.delete("some_content_id", payload_version: "1")

      expect(logger).to have_received(:info).with("[DELETE some_content_id@v1]")
    end
  end
end
