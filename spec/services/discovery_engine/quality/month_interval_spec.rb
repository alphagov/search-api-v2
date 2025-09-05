RSpec.describe DiscoveryEngine::Quality::MonthInterval do
  subject(:month_interval) { described_class.new(year, month) }

  let(:year) { 1989 }
  let(:month) { 12 }

  describe ".previous_month" do
    around do |example|
      Timecop.freeze(1987, 7, 21) { example.call }
    end

    context "without an argument" do
      it "returns a month interval for one month ago" do
        expect(described_class.previous_month).to eq(described_class.new(1987, 6))
      end
    end

    context "with an argument" do
      it "returns a month interval for the specified number of months ago" do
        expect(described_class.previous_month(11)).to eq(described_class.new(1986, 8))
      end
    end
  end

  describe "#year" do
    it "returns the year" do
      expect(month_interval.year).to eq(1989)
    end
  end

  describe "#month" do
    it "returns the month" do
      expect(month_interval.month).to eq(12)
    end
  end

  describe "#to_s" do
    it "returns the formatted string representation of the month interval" do
      expect(month_interval.to_s).to eq("1989-12")
    end
  end

  describe "#first_day_of_month" do
    it "returns the formatted string representation of the month interval" do
      expect(month_interval.first_day_of_month).to eq("1989-12-01")
    end
  end
end
