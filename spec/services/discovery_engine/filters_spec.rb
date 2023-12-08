RSpec.describe DiscoveryEngine::Filters do
  describe "#filter_expression" do
    subject(:filter_expression) { described_class.new(query_params).filter_expression }

    context "when no relevant query params are present" do
      let(:query_params) { {} }

      it { is_expected.to be_nil }
    end

    context "with a single reject_link parameter" do
      let(:query_params) { { q: "garden centres", reject_link: "/foo" } }

      it "calls the client with the expected parameters" do
        expect(filter_expression).to eq('NOT link: ANY("/foo")')
      end
    end

    context "with several reject_link parameter" do
      let(:query_params) { { q: "garden centres", reject_link: ["/foo", "/bar"] } }

      it "calls the client with the expected parameters" do
        expect(filter_expression).to eq('NOT link: ANY("/foo","/bar")')
      end
    end
  end
end
