RSpec.describe QualityMonitoring::CheckResultInvariants do
  subject(:check_result_invariants) { described_class.new(search_service_klass:) }

  let(:search_service_klass) { double("DiscoveryEngine::Query::Search", new: client) }
  let(:client) { double("SearchService::Client") }

  describe "#violations" do
    subject(:violations) { check_result_invariants.violations }

    context "when all invariants are satisfied" do
      before do
        allow(client).to receive(:result_set).and_return(
          ResultSet.new(results: [
            Result.new(link: "/expected/result/1"),
          ]),
          ResultSet.new(results: [
            Result.new(link: "/expected/result/2"),
            Result.new(link: "/expected/result/2.5"),
          ]),
          ResultSet.new(results: [
            Result.new(link: "/expected/result/3.5"),
            Result.new(link: "/expected/result/3"),
          ]),
          ResultSet.new(results: [
            Result.new(link: "/expected/result/4"),
            Result.new(link: "/expected/result/abcde"),
          ]),
        )
      end

      it { is_expected.to be_empty }
    end

    context "when invariants are violated" do
      let(:expected_violations) do
        [
          QualityMonitoring::ResultInvariantViolation.new(
            query: "query two",
            expected_link: "/expected/result/2.5",
          ),
          QualityMonitoring::ResultInvariantViolation.new(
            query: "query four",
            expected_link: "/expected/result/4",
          ),
        ]
      end

      before do
        allow(client).to receive(:result_set).and_return(
          ResultSet.new(results: [
            Result.new(link: "/expected/result/1"),
          ]),
          ResultSet.new(results: [
            Result.new(link: "/expected/result/2"),
            Result.new(link: "/expected/result/42"),
          ]),
          ResultSet.new(results: [
            Result.new(link: "/expected/result/3.5"),
            Result.new(link: "/expected/result/3"),
          ]),
          ResultSet.new(results: [
            Result.new(link: "/expected/result/123"),
            Result.new(link: "/expected/result/321"),
          ]),
        )
      end

      it { is_expected.to eq(expected_violations) }
    end
  end
end
