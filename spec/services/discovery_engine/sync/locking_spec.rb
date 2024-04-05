RSpec.describe DiscoveryEngine::Sync::Locking do
  subject(:lockable) { Class.new.include(described_class).new }

  let(:content_id) { "some-content-id" }
  let(:payload_version) { 10 }

  let(:redis_client) { double("Redis Client") }

  before do
    allow(Rails.application.config.redis_pool).to receive(:with).and_yield(redis_client)
  end

  describe "#outdated_payload_version?" do
    subject(:outdated_payload_version) { lockable.outdated_payload_version?(content_id, payload_version:) }

    let(:remote_version) { 42 }

    before do
      allow(redis_client).to receive(:get)
        .with("search_api_v2:latest_synced_version:some-content-id")
        .and_return(remote_version.to_s)
    end

    context "when payload_version is nil" do
      let(:payload_version) { nil }

      it { is_expected.to be(false) }
    end

    context "when there is no remote version" do
      let(:remote_version) { nil }

      it { is_expected.to be(false) }
    end

    context "when remote version is equal to payload version" do
      let(:remote_version) { payload_version }

      it { is_expected.to be(true) }
    end

    context "when remote version is greater than payload version" do
      let(:remote_version) { payload_version + 1 }

      it { is_expected.to be(true) }
    end

    context "when remote version is less than payload version" do
      let(:remote_version) { payload_version - 1 }

      it { is_expected.to be(false) }
    end
  end
end
