RSpec.describe "PublishingApiDocument schema-compliant metadata generation" do
  %w[
    external_content_message
    historic_news_story_message
    independent_report_message
    organisation_message
    press_release_message
    travel_advice_message
    world_taxon_message
  ].each do |message_fixture|
    context "when processing a '#{message_fixture}'" do
      let(:document_hash) { json_fixture_as_hash("message_queue/#{message_fixture}.json") }
      let(:document) { PublishingApiDocument::Publish.new(document_hash.deep_symbolize_keys) }

      it "results in a document validating against the datastore schema" do
        expect(document.metadata).to match_json_schema(metadata_json_schema)
      end
    end
  end
end
