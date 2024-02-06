RSpec.describe QualityMonitoring::Judge do
  subject(:judge) { described_class.new(result_links, expected_links) }

  let(:expected_links) { %w[A B C D E F G H I J] }

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
