RSpec.shared_context "with sync context" do
  let(:client) { double("DocumentService::Client", update_document: nil, delete_document: nil) }
  let(:logger) { double("Logger", add: nil) }

  let(:lock) { instance_double(Coordination::DocumentLock, acquire: true, release: true) }
  let(:version_cache) { instance_double(Coordination::DocumentVersionCache, sync_required?: sync_required, set_as_latest_synced_version: nil) }

  before do
    allow(Kernel).to receive(:sleep).and_return(nil)
    allow(Rails).to receive(:logger).and_return(logger)
    allow(Rails.configuration).to receive(:discovery_engine_datastore_branch).and_return("branch")
    allow(GovukError).to receive(:notify)

    allow(Coordination::DocumentLock).to receive(:new).with("some_content_id").and_return(lock)
    allow(Coordination::DocumentVersionCache).to receive(:new)
      .with("some_content_id", payload_version: "1").and_return(version_cache)
  end
end

RSpec.shared_examples "a successful sync operation" do |type|
  it "sets the new latest remote version" do
    expect(version_cache).to have_received(:set_as_latest_synced_version)
  end

  it "logs the delete operation" do
    expect(logger).to have_received(:add).with(
      Logger::Severity::INFO,
      "[#{described_class}] Successful #{type} content_id:some_content_id payload_version:1",
    )
  end

  it "acquires and releases the lock" do
    expect(lock).to have_received(:acquire)
    expect(lock).to have_received(:release)
  end
end

RSpec.shared_examples "a noop sync operation" do
  it "does not set the remote version" do
    expect(version_cache).not_to have_received(:set_as_latest_synced_version)
  end

  it "logs that the document hasn't been deleted" do
    expect(logger).to have_received(:add).with(
      Logger::Severity::INFO,
      "[#{described_class}] Ignored as newer version already synced content_id:some_content_id payload_version:1",
    )
  end
end

RSpec.shared_examples "a failed sync operation after the maximum attempts" do |type|
  it "logs the failed attempts" do
    expect(logger).to have_received(:add).with(
      Logger::Severity::WARN,
      "[#{described_class}] Failed attempt 1 to #{type} document (Something went wrong), retrying content_id:some_content_id payload_version:1",
    )
    expect(logger).to have_received(:add).with(
      Logger::Severity::WARN,
      "[#{described_class}] Failed attempt 2 to #{type} document (Something went wrong), retrying content_id:some_content_id payload_version:1",
    )
    expect(logger).to have_received(:add).with(
      Logger::Severity::ERROR,
      "[#{described_class}] Failed on attempt 3 to #{type} document (Something went wrong), giving up content_id:some_content_id payload_version:1",
    )
  end

  it "sends the error to Sentry" do
    expect(GovukError).to have_received(:notify)
  end
end

RSpec.shared_examples "a sync operation that eventually succeeds" do |type|
  it "logs the failed and successful attempts" do
    expect(logger).to have_received(:add).with(
      Logger::Severity::WARN,
      "[#{described_class}] Failed attempt 1 to #{type} document (Something went wrong), retrying content_id:some_content_id payload_version:1",
    ).ordered
    expect(logger).to have_received(:add).with(
      Logger::Severity::WARN,
      "[#{described_class}] Failed attempt 2 to #{type} document (Something went wrong), retrying content_id:some_content_id payload_version:1",
    ).ordered
    expect(logger).to have_received(:add).with(
      Logger::Severity::INFO,
      "[#{described_class}] Successful #{type} content_id:some_content_id payload_version:1",
    ).ordered
  end

  it "does not send an error to Sentry" do
    expect(GovukError).not_to have_received(:notify)
  end
end
