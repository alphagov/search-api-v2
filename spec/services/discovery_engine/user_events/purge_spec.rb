RSpec.describe DiscoveryEngine::UserEvents::Purge do
  subject(:import) { described_class.new(from:, to:, client:) }

  let(:from) { Date.new(2000, 1, 1) }
  let(:to) { Date.new(2000, 1, 30) }
  let(:client) do
    instance_double(
      ::Google::Cloud::DiscoveryEngine::V1::UserEventService::Client,
      purge_user_events: operation,
    )
  end
  let(:operation) { instance_double(Gapic::Operation, wait_until_done!: nil) }

  around do |example|
    Timecop.freeze(Time.zone.local(1989, 12, 13, 1, 2, 3)) do
      example.call
    end
  end

  describe ".purge_final_week_of_retention_period" do
    let(:purge) { instance_double(described_class, call: nil) }

    before do
      allow(described_class).to receive(:new).and_return(purge)

      described_class.purge_final_week_of_retention_period
    end

    it "purges one week's worth of user events from the final day of the retention period" do
      expect(described_class).to have_received(:new).with(
        from: Date.new(1987, 12, 13),
        to: Date.new(1987, 12, 20),
      )
    end
  end

  describe "#call" do
    it "purges user events within the specified date range" do
      import.call

      expect(client).to have_received(:purge_user_events).with(
        parent: DataStore.default.name,
        filter: 'eventTime > "2000-01-01T00:00:00Z" eventTime < "2000-01-31T00:00:00Z"',
        force: true,
      )
    end
  end

  context "with an excessively long date range" do
    let(:from) { Date.new(2000, 1, 1) }
    let(:to) { Date.new(2000, 2, 1) }

    it "raises an error" do
      expect { import.call }.to raise_error(ArgumentError, /date range is too long/)
    end
  end

  context "with an inverted date range" do
    let(:from) { Date.new(2000, 1, 31) }
    let(:to) { Date.new(2000, 1, 1) }

    it "raises an error" do
      expect { import.call }.to raise_error(ArgumentError, /from date is after to date/)
    end
  end

  context "when the remote operation is unsuccessful" do
    let(:error_result) { double("error", error?: true, results: double(message: "BROKEN")) }

    before do
      allow(operation).to receive(:wait_until_done!).and_yield(error_result)
    end

    it "raises an error" do
      expect { import.call }.to raise_error("BROKEN")
    end
  end
end
