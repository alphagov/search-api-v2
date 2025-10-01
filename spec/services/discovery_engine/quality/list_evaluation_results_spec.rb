RSpec.describe DiscoveryEngine::Quality::ListEvaluationResults do
  subject(:list_results) { described_class.new(evaluation_name, sample_query_set_name, serving_config) }

  let(:evaluation_name) { "projects/780375417592/locations/global/evaluations/2b53e0c6" }
  let(:sample_query_set_name) { "clickstream_09-2025" }
  let(:serving_config) { "projects/780375417592/locations/global/collections/default_collection/engines/govuk_global/servingConfigs/default" }
  let(:serving_config_display_name) { "default" }
  let(:evaluation_service) { double("evaluation_service", list_evaluation_results: raw_api_response) }
  let(:raw_api_response) { double("raw_api_resonse", to_json: response.to_json) }
  let(:response) do
    [
      {
        "sample_query": {
          "name": "projects/780375417592/locations/global/sampleQuerySets/explicit_2025-07/sampleQueries/0f8d7aac-a483-4aee-942c-0382dfd61c98",
          "query_entry": {
            "query": "driving licence",
            "targets": [
              {
                "uri": "f725a60e-a666-4269-82b0-946ecfb84b7c",
                "score": 1.0,
              },
              {
                "uri": "bee455d5-5a4f-440a-88be-eb65ae8fde7d",
                "score": 1.0,
              },
            ],
          },
        },
        "quality_metrics": {
          "doc_recall": {
            "top_3": 1.0,
            "top_5": 1.0,
            "top_10": 1.0,
          },
          "doc_precision": {
            "top_3": 0.3333333333333333,
            "top_5": 0.2,
            "top_10": 0.2,
          },
          "doc_ndcg": {
            "top_3": 0.3065735963827292,
            "top_5": 0.3065735963827292,
            "top_10": 0.5109559939712153,
          },
          "page_recall": {},
          "page_ndcg": {},
        },
      },
    ]
  end

  before do
    allow(DiscoveryEngine::Clients)
      .to receive(:evaluation_service)
      .and_return(evaluation_service)
  end

  describe "#formatted_json" do
    it "fetches list results from the list_evaluations_results endpoint" do
      list_results.formatted_json

      expect(evaluation_service)
        .to have_received(:list_evaluation_results)
        .with(evaluation: evaluation_name, page_size: 1000)
    end

    it "formats the response" do
      formatted_results = {
        "evaluation_name" => evaluation_name,
        "serving_configuration_name" => serving_config_display_name,
        "evaluation_results" => response,
      }
      expect(list_results.formatted_json).to eq(formatted_results.to_json)
    end
  end
end
