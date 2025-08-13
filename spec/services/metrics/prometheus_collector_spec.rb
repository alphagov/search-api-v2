RSpec.describe Metrics::PrometheusCollector do
  subject(:collector) { described_class.new(registry) }

  let(:registry) { double("registry") }
  let(:month) { :last_month }
  let(:table_id) { "clickstream" }

  let(:evaluation_response) do
    {
      doc_recall: {
        top_1: 0.988,
        top_3: 0.995,
        top_5: 0.998,
        top_10: 0.999,
      },
      doc_precision: {
        top_1: 0.988,
        top_3: 0.953,
        top_5: 0.896,
        top_10: 0.752,
      },
      doc_ndcg: {
        top_1: 0.988,
        top_3: 0.961,
        top_5: 0.929,
        top_10: 0.887,
      },
      page_recall: {},
      page_ndcg: {},
    }
  end
  let(:recall_gauge) { double("recall_gauge") }
  let(:precision_gauge) { double("precision_gauge") }
  let(:ndcg_gauge) { double("ndcg_gauge") }

  before do
    allow(registry).to receive(:gauge)
      .with(:search_api_v2_evaluation_monitoring_recall, anything).and_return(recall_gauge)
    allow(registry).to receive(:gauge)
      .with(:search_api_v2_evaluation_monitoring_precision, anything).and_return(precision_gauge)
    allow(registry).to receive(:gauge)
      .with(:search_api_v2_evaluation_monitoring_ndcg, anything).and_return(ndcg_gauge)
  end

  describe "#record_evaluations" do
    it "records the recall, precision and ndcg score" do
      expect(recall_gauge).to receive(:set)
        .with(0.988, { labels: { top: "1", month:, dataset: "clickstream" } })
      expect(recall_gauge).to receive(:set)
        .with(0.995, { labels: { top: "3", month:, dataset: "clickstream" } })
      expect(recall_gauge).to receive(:set)
        .with(0.998, { labels: { top: "5", month:, dataset: "clickstream" } })
      expect(recall_gauge).to receive(:set)
        .with(0.999, { labels: { top: "10", month:, dataset: "clickstream" } })

      expect(precision_gauge).to receive(:set)
        .with(0.988, { labels: { top: "1", month:, dataset: "clickstream" } })
      expect(precision_gauge).to receive(:set)
        .with(0.953, { labels: { top: "3", month:, dataset: "clickstream" } })
      expect(precision_gauge).to receive(:set)
        .with(0.896, { labels: { top: "5", month:, dataset: "clickstream" } })
      expect(precision_gauge).to receive(:set)
        .with(0.752, { labels: { top: "10", month:, dataset: "clickstream" } })

      expect(ndcg_gauge).to receive(:set)
        .with(0.988, { labels: { top: "1", month:, dataset: "clickstream" } })
      expect(ndcg_gauge).to receive(:set)
        .with(0.961, { labels: { top: "3", month:, dataset: "clickstream" } })
      expect(ndcg_gauge).to receive(:set)
        .with(0.929, { labels: { top: "5", month:, dataset: "clickstream" } })
      expect(ndcg_gauge).to receive(:set)
        .with(0.887, { labels: { top: "10", month:, dataset: "clickstream" } })

      collector.record_evaluations(evaluation_response, month, table_id)
    end
  end
end
