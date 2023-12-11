RSpec.describe DiscoveryEngine::Query::Filters do
  describe "#filter_expression" do
    subject(:filter_expression) { described_class.new(query_params).filter_expression }

    context "when no relevant query params are present" do
      let(:query_params) { {} }

      it { is_expected.to be_nil }
    end

    context "with reject_link" do
      context "with an empty parameter" do
        let(:query_params) { { q: "garden centres", reject_link: "" } }

        it { is_expected.to be_nil }
      end

      context "with a single parameter" do
        let(:query_params) { { q: "garden centres", reject_link: "/foo" } }

        it { is_expected.to eq('(NOT link: ANY("/foo"))') }
      end

      context "with several parameters" do
        let(:query_params) { { q: "garden centres", reject_link: ["/foo", "/bar"] } }

        it { is_expected.to eq('(NOT link: ANY("/foo","/bar"))') }
      end
    end

    context "with filter_content_purpose_supergroup" do
      context "with an empty parameter" do
        let(:query_params) { { q: "garden centres", filter_content_purpose_supergroup: "" } }

        it { is_expected.to be_nil }
      end

      context "with a single parameter" do
        let(:query_params) { { q: "garden centres", filter_content_purpose_supergroup: "services" } }

        it { is_expected.to eq('(content_purpose_supergroup: ANY("services"))') }
      end

      context "with several parameters" do
        let(:query_params) { { q: "garden centres", filter_content_purpose_supergroup: %w[services guidance] } }

        it { is_expected.to eq('(content_purpose_supergroup: ANY("services","guidance"))') }
      end
    end

    context "with several filters specified" do
      let(:query_params) { { q: "garden centres", reject_link: "/foo", filter_content_purpose_supergroup: "services" } }

      it { is_expected.to eq('(NOT link: ANY("/foo")) AND (content_purpose_supergroup: ANY("services"))') }
    end

    context "with filters containing escapable characters" do
      let(:query_params) { { q: "garden centres", filter_content_purpose_supergroup: "foo\"\\bar" } }

      it { is_expected.to eq('(content_purpose_supergroup: ANY("foo\\"\\\\bar"))') }
    end
  end
end
