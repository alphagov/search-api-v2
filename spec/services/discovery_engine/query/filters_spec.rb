RSpec.describe DiscoveryEngine::Query::Filters do
  describe "#filter_expression" do
    subject(:filter_expression) { described_class.new(query_params).filter_expression }

    context "when no relevant query params are present" do
      let(:query_params) { {} }

      it { is_expected.to be_nil }
    end

    context "with a reject string filter" do
      context "with an empty parameter" do
        let(:query_params) { { q: "garden centres", reject_link: "" } }

        it { is_expected.to be_nil }
      end

      context "with a single parameter" do
        let(:query_params) { { q: "garden centres", reject_link: "/foo" } }

        it { is_expected.to eq('NOT link: ANY("/foo")') }
      end

      context "with several parameters" do
        let(:query_params) { { q: "garden centres", reject_link: ["/foo", "/bar"] } }

        it { is_expected.to eq('NOT link: ANY("/foo","/bar")') }
      end

      context "with an unknown field" do
        let(:query_params) { { q: "garden centres", reject_foo: "bar" } }

        it { is_expected.to be_nil }
      end
    end

    context "with an 'any' string filter" do
      context "with an empty parameter" do
        let(:query_params) { { q: "garden centres", filter_content_purpose_supergroup: "" } }

        it { is_expected.to be_nil }
      end

      context "with a single parameter" do
        let(:query_params) do
          { q: "garden centres", filter_content_purpose_supergroup: "services" }
        end

        it { is_expected.to eq('content_purpose_supergroup: ANY("services")') }
      end

      context "with several parameters" do
        let(:query_params) do
          { q: "garden centres", filter_content_purpose_supergroup: %w[services guidance] }
        end

        it { is_expected.to eq('content_purpose_supergroup: ANY("services","guidance")') }
      end

      context "with an unknown field" do
        let(:query_params) { { q: "garden centres", filter_foo: "bar" } }

        it { is_expected.to be_nil }
      end
    end

    context "with an 'all' string filter" do
      context "with an empty parameter" do
        let(:query_params) { { q: "garden centres", filter_all_part_of_taxonomy_tree: "" } }

        it { is_expected.to be_nil }
      end

      context "with a single parameter" do
        let(:query_params) { { q: "garden centres", filter_all_part_of_taxonomy_tree: "cafe-1234" } }

        it { is_expected.to eq('part_of_taxonomy_tree: ANY("cafe-1234")') }
      end

      context "with several parameters" do
        let(:query_params) do
          { q: "garden centres", filter_all_part_of_taxonomy_tree: %w[cafe-1234 face-5678] }
        end

        it { is_expected.to eq('(part_of_taxonomy_tree: ANY("cafe-1234")) AND (part_of_taxonomy_tree: ANY("face-5678"))') }
      end

      context "with an unknown field" do
        let(:query_params) { { q: "garden centres", filter_all_foo: "bar" } }

        it { is_expected.to be_nil }
      end
    end

    context "with a timestamp filter" do
      context "with an empty parameter" do
        let(:query_params) { { q: "garden centres", filter_public_timestamp: "" } }

        it { is_expected.to be_nil }
      end

      context "with a from parameter" do
        let(:query_params) { { q: "garden centres", filter_public_timestamp: "from:1989-12-13" } }

        it { is_expected.to eq("public_timestamp: IN(629510400,*)") }
      end

      context "with a to parameter" do
        let(:query_params) { { q: "garden centres", filter_public_timestamp: "to:1989-12-13" } }

        it { is_expected.to eq("public_timestamp: IN(*,629596799)") }
      end

      context "with both from and to parameters" do
        let(:query_params) { { q: "garden centres", filter_public_timestamp: "from:1989-12-13,to:1989-12-13" } }

        it { is_expected.to eq("public_timestamp: IN(629510400,629596799)") }
      end

      context "with an invalid from parameter" do
        let(:query_params) { { q: "garden centres", filter_public_timestamp: "from:1989" } }

        it { is_expected.to be_nil }
      end

      context "with an invalid to parameter" do
        let(:query_params) { { q: "garden centres", filter_public_timestamp: "to:12-13" } }

        it { is_expected.to be_nil }
      end

      context "with an invalid filter_all type" do
        let(:query_params) { { q: "garden centres", filter_all_public_timestamp: "from:1989-12-13" } }

        it { is_expected.to be_nil }
      end

      context "with an invalid reject type" do
        let(:query_params) { { q: "garden centres", reject_public_timestamp: "from:1989-12-13" } }

        it { is_expected.to be_nil }
      end
    end

    context "with several filters specified" do
      let(:query_params) do
        {
          q: "garden centres",
          reject_link: "/foo",
          filter_content_purpose_supergroup: "services",
          filter_all_part_of_taxonomy_tree: %w[cafe-1234 face-5678],
          filter_public_timestamp: "from:1989-12-13,to:1989-12-13",
        }
      end

      it { is_expected.to eq('(NOT link: ANY("/foo")) AND (content_purpose_supergroup: ANY("services")) AND ((part_of_taxonomy_tree: ANY("cafe-1234")) AND (part_of_taxonomy_tree: ANY("face-5678"))) AND (public_timestamp: IN(629510400,629596799))') }
    end

    context "with filters containing escapable characters" do
      let(:query_params) { { q: "garden centres", filter_content_purpose_supergroup: "foo\"\\bar" } }

      it { is_expected.to eq('content_purpose_supergroup: ANY("foo\\"\\\\bar")') }
    end
  end
end
