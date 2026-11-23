require "rake"

RSpec.describe "generate_summaries rake tasks" do
  include ActiveSupport::Testing::TimeHelpers

  describe "generate_summaries:summaries_csv" do
    let(:task) { Rake::Task["generate_summaries:summaries_csv"] }
    let(:exporter) { instance_double(DiscoveryEngine::Summary::CsvExport) }

    before do
      task.reenable
      allow(DiscoveryEngine::Summary::CsvExport).to receive(:new).and_return(exporter)
      allow(exporter).to receive(:export)
    end

    it "exports summaries to the specified CSV file" do
      expect {
        task.invoke("input.csv", "output.csv")
      }.to output(/Wrote output\.csv/).to_stdout

      expect(exporter).to have_received(:export).with("input.csv", "output.csv")
    end

    it "generates a default output filename" do
      travel_to Time.zone.local(2026, 11, 16, 12, 30, 45) do
        expect {
          task.invoke("input.csv")
        }.to output(/Wrote summaries_20261116123045\.csv\n/).to_stdout
      end

      expect(exporter).to have_received(:export)
                            .with("input.csv", "summaries_20261116123045.csv")
    end

    it "requires an input filename" do
      expect {
        task.invoke
      }.to raise_error(SystemExit)
             .and output("Usage: rake generate_summaries:summaries_csv[input.csv,output.csv]\n").to_stderr
    end
  end

  describe "generate_summaries:raw_response" do
    let(:query) { instance_double(DiscoveryEngine::Summary::Query) }
    let(:response) { Google::Cloud::DiscoveryEngine::V1::SearchResponse.new(summary: { summary_text: "A summary" }) }

    before do
      allow(DiscoveryEngine::Summary::Query).to receive(:new).and_return(query)
      allow(query).to receive(:response).and_return(response)
      Rake::Task["generate_summaries:raw_response"].reenable
    end

    it "prints the full JSON response" do
      expect { Rake::Task["generate_summaries:raw_response"].invoke("my query") }
        .to output("#{JSON.pretty_generate(response.to_h)}\n").to_stdout
    end
  end
end
