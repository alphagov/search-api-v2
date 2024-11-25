RSpec.describe DiscoveryEngine::UserEvents::Import do
  subject(:import) { described_class.new(event_type, date:, client:) }

  let(:event_type) { "search" }
  let(:date) { Date.new(2000, 1, 1) }

  let(:client) do
    instance_double(
      ::Google::Cloud::DiscoveryEngine::V1::UserEventService::Client,
      import_user_events: operation,
    )
  end
  let(:operation) { instance_double(Gapic::Operation, wait_until_done!: nil) }

  before do
    allow(Rails.configuration).to receive_messages(
      discovery_engine_datastore: "data/store",
      google_cloud_project_id: "my-fancy-project",
    )
  end

  describe ".import_all" do
    let(:importer) { instance_double(described_class, call: nil) }

    before do
      allow(described_class).to receive(:new).and_return(importer)
    end

    it "triggers an individual import for each event type with the given date" do
      described_class.import_all(date)

      expect(described_class).to have_received(:new).with("search", date:)
      expect(described_class).to have_received(:new).with("view-item", date:)
      expect(described_class).to have_received(:new).with("view-item-external-link", date:)

      expect(importer).to have_received(:call).exactly(3).times
    end
  end

  describe "#call" do
    before do
      Timecop.freeze(Time.zone.local(1989, 12, 13, 1, 2, 3)) do
        import.call
      end
    end

    context "with a specific date" do
      let(:date) { Date.new(2000, 1, 1) }

      it "triggers an import of that day's user events" do
        expect(client).to have_received(:import_user_events).with(
          bigquery_source: {
            project_id: "my-fancy-project",
            dataset_id: "analytics_events_vertex",
            table_id: "search-event",
            partition_date: Google::Type::Date.new(year: 2000, month: 1, day: 1),
          },
          parent: "data/store",
        )
      end
    end

    context "with today's date" do
      let(:date) { Date.new(1989, 12, 13) }

      it "triggers an import of today's intraday user events" do
        expect(client).to have_received(:import_user_events).with(
          bigquery_source: {
            project_id: "my-fancy-project",
            dataset_id: "analytics_events_vertex",
            table_id: "search-intraday-event",
            partition_date: Google::Type::Date.new(year: 1989, month: 12, day: 13),
          },
          parent: "data/store",
        )
      end
    end

    context "when an error occurs during import" do
      let(:date) { Date.new(2000, 1, 1) }
      let(:error_result) { double("error", error?: true, results: double(message: "BROKEN")) }

      before do
        allow(operation).to receive(:wait_until_done!).and_yield(error_result)
      end

      it "raises an error" do
        expect { import.call }.to raise_error("BROKEN")
      end
    end
  end
end
