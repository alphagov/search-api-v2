RSpec.describe Coordination::DocumentVersionCache do
  subject(:document_version_cache) { described_class.new("content-id", payload_version:) }

  let(:payload_version) { 1234 }
  let(:remote_version) { nil }

  let(:redis_client) { instance_double(Redis, get: nil, set: nil) }

  before do
    allow(Rails.application.config.redis_pool).to receive(:with).and_yield(redis_client)
    allow(redis_client).to receive(:get)
        .with("search_api_v2:latest_synced_version:content-id").and_return(remote_version)
  end

  describe "outdated?" do
    subject(:outdated) { document_version_cache.outdated? }

    context "when the remote version is newer" do
      let(:remote_version) { payload_version + 1 }

      it { is_expected.to be true }
    end

    context "when the remote version is the same" do
      let(:remote_version) { payload_version }

      it { is_expected.to be true }
    end

    context "when the remote version is older" do
      let(:remote_version) { payload_version - 1 }

      it { is_expected.to be false }
    end

    context "when there is no remote version" do
      let(:remote_version) { nil }

      it { is_expected.to be false }
    end

    context "when there is no payload version" do
      let(:payload_version) { nil }

      it { is_expected.to be false }
    end
  end
end
