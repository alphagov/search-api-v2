RSpec.describe QualityMonitoring::Judge do
  subject(:judge) { described_class.new(result_links, expected_links) }

  let(:expected_links) { %w[A B C D E F G H I J] }

  describe ".for_query" do
    subject(:judge) { described_class.for_query(query, expected_links, cutoff:) }

    let(:query) { "query" }
    let(:cutoff) { 10 }

    let(:search) { instance_double(DiscoveryEngine::Query::Search, result_set:) }
    let(:result_set) { ResultSet.new(results:) }
    let(:results) do
      [
        Result.new(link: "X"),
        Result.new(link: "Y"),
        Result.new(link: "Z"),
      ]
    end

    before do
      allow(DiscoveryEngine::Query::Search).to receive(:new)
        .with({ q: query }).and_return(search)
    end

    it "returns a correctly set up instance of Judge" do
      expect(judge.result_links).to eq(%w[X Y Z])
      expect(judge.expected_links).to eq(expected_links)
    end
  end

  describe "#initialize" do
    context "when expected links is empty" do
      let(:result_links) { [] }
      let(:expected_links) { [] }

      it "raises an error" do
        expect { judge }.to raise_error(ArgumentError, "at least one expected link is required")
      end
    end
  end

  describe "#precision" do
    context "when there is a partial match" do
      let(:result_links) { %w[U O I E A] }

      it "calculates precision correctly" do
        expect(judge.precision).to eq(0.6)
      end
    end

    context "when there is a full match" do
      let(:result_links) { expected_links }

      it "returns 1" do
        expect(judge.precision).to eq(1)
      end
    end

    context "when there are no result links" do
      let(:result_links) { [] }

      it "returns 0" do
        expect(judge.precision).to eq(0)
      end
    end
  end

  describe "#recall" do
    context "when there is a partial match" do
      let(:result_links) { %w[U O I E A] }

      it "calculates recall correctly" do
        expect(judge.recall).to eq(0.3)
      end
    end

    context "when there is a full match" do
      let(:result_links) { expected_links }

      it "returns 1" do
        expect(judge.recall).to eq(1)
      end
    end

    context "when there are no result links" do
      let(:result_links) { [] }

      it "returns 0" do
        expect(judge.recall).to eq(0)
      end
    end
  end
end
