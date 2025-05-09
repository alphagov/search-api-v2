RSpec.describe DiscoveryEngine::Autocomplete::Complete do
  subject(:completion) { described_class.new(query, client:) }

  let(:client) { double("completion service", complete_query:) }

  describe "#completion_result" do
    subject(:completion_result) { completion.completion_result }

    let(:query) { "foo" }
    let(:complete_query) { double("response", query_suggestions:) }
    let(:query_suggestions) { %w[foo foobar foobaz].map { double("suggestion", suggestion: _1) } }

    it "returns the suggestions from the search response" do
      expect(completion_result.suggestions).to eq(%w[foo foobar foobaz])
    end

    it "makes a request to the completion service with the right parameters" do
      completion_result

      expect(client).to have_received(:complete_query).with(
        data_store: DataStore.default.name,
        query:,
        query_model: "user-event",
      )
    end

    context "when the query is empty" do
      let(:query) { "" }

      it "returns an empty array and does not make a request" do
        expect(completion_result.suggestions).to eq([])
        expect(client).not_to have_received(:complete_query)
      end
    end

    context "when the completion service fails" do
      before do
        allow(client).to receive(:complete_query).and_raise(error)
        allow(Rails.logger).to receive(:warn)
      end

      context "and the error is actionable" do
        let(:error) { Google::Cloud::PermissionDeniedError.new("Permission denied") }

        it "returns the error from Google Cloud" do
          expect { completion_result }.to raise_error(error)
        end
      end
    end
  end
end
