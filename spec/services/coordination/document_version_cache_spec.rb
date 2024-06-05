RSpec.describe Coordination::DocumentVersionCache do
  subject(:document_version_cache) { described_class.new("content-id", payload_version:) }

  let(:payload_version) { 1234 }

  pending
end
