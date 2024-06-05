RSpec.describe Coordination::DocumentLock do
  subject(:document_lock) { described_class.new("content-id") }

  let(:redlock_client) { instance_double(Redlock::Client) }

  before do
    allow(Redlock::Client).to receive(:new).and_return(redlock_client)
  end

  describe "#acquire" do
    context "when locking succeeds" do
      before do
        allow(redlock_client).to receive(:lock).and_return({ lock: :info })
      end

      it "returns true" do
        expect(document_lock.acquire).to be true
      end

      it "acquires a lock from the Redlock client for 30 seconds" do
        document_lock.acquire

        expect(redlock_client).to have_received(:lock).with("search_api_v2:sync_lock:content-id", 30_000)
      end
    end

    context "when locking fails" do
      before do
        allow(redlock_client).to receive(:lock).and_return(false)
        allow(Rails.logger).to receive(:warn)
      end

      it "returns false" do
        expect(document_lock.acquire).to be false
      end

      it "logs an error" do
        document_lock.acquire

        expect(Rails.logger).to have_received(:warn)
          .with("[Coordination::DocumentLock] Failed to acquire lock for document: content-id")
      end
    end

    context "when locking raises an error" do
      let(:error) { StandardError.new("uh oh") }

      before do
        allow(redlock_client).to receive(:lock).and_raise(error)
        allow(Rails.logger).to receive(:warn)
        allow(GovukError).to receive(:notify)
      end

      it "returns false" do
        expect(document_lock.acquire).to be false
      end

      it "logs an error" do
        document_lock.acquire

        expect(Rails.logger).to have_received(:warn)
          .with("[Coordination::DocumentLock] Failed to acquire lock for document: content-id")
      end

      it "sends the error to GovukError" do
        document_lock.acquire

        expect(GovukError).to have_received(:notify).with(error)
      end
    end
  end

  describe "#unlock" do
    context "when the document is not locked" do
      it "returns false" do
        expect(document_lock.release).to be false
      end
    end

    context "when the document is locked" do
      before do
        allow(redlock_client).to receive(:lock).and_return({ lock: :info })
        allow(redlock_client).to receive(:unlock)

        document_lock.acquire
      end

      it "releases the lock" do
        document_lock.release

        expect(redlock_client).to have_received(:unlock).with({ lock: :info })
      end
    end
  end
end
