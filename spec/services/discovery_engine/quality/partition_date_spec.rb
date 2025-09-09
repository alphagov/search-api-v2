RSpec.describe DiscoveryEngine::Quality::PartitionDate do
  subject(:partition_date) { described_class.new(month_label:, month:, year:) }

  describe ".calculate" do
    around do |example|
      Timecop.freeze(1987, 7, 21) { example.call }
    end

    context "with a month label of :last_month" do
      let(:month_label) { :last_month }
      let(:month) { nil }
      let(:year) { nil }

      it "returns a Date object for the first day of last month" do
        expect(partition_date.calculate).to eq(Date.new(1987, 6, 1))
      end
    end

    context "with a month label of :month_before_last" do
      let(:month_label) { :month_before_last }
      let(:month) { nil }
      let(:year) { nil }

      it "returns a Date object for the first day of last month" do
        expect(partition_date.calculate).to eq(Date.new(1987, 5, 1))
      end
    end

    context "with month and year" do
      let(:month_label) { nil }
      let(:month) { 10 }
      let(:year) { 2020 }

      it "returns a Date object using the provided month and year values" do
        expect(partition_date.calculate).to eq(Date.new(2020, 10, 1))
      end
    end
  end
end
