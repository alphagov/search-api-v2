require "rake"
Rails.logger.debug "Loading Rake tasks..."
RSpec.describe "generate_answers rake tasks" do
  include ActiveSupport::Testing::TimeHelpers

  describe "generate_answers:answers_csv" do
    let(:task) { Rake::Task["generate_answers:answers_csv"] }
    let(:exporter) { instance_double(DiscoveryEngine::Answer::CsvExport) }

    before do
      task.reenable
      Rails.logger.debug task.actions.size
      allow(DiscoveryEngine::Answer::CsvExport).to receive(:new).and_return(exporter)
      allow(exporter).to receive(:export)
    end

    it "exports answers to the specified CSV file" do
      expect {
        task.invoke("input.csv", "output.csv")
      }.to output(/Wrote output\.csv/).to_stdout

      expect(exporter).to have_received(:export).with("input.csv", "output.csv")
    end

    it "generates a default output filename" do
      travel_to Time.zone.local(2026, 11, 16, 12, 30, 45) do
        expect {
          task.invoke("input.csv")
        }.to output(/Wrote answers_20261116123045\.csv\n/).to_stdout
      end

      expect(exporter).to have_received(:export)
                            .with("input.csv", "answers_20261116123045.csv")
    end

    it "requires an input filename" do
      expect {
        task.invoke
      }.to raise_error(SystemExit)
             .and output("Usage: rake generate_answers:answers_csv[input.csv,output.csv]\n").to_stderr
    end
  end

  describe "generate_answers:raw_response" do
    let(:query) { instance_double(DiscoveryEngine::Answer::Query) }
    let(:response) { Google::Cloud::DiscoveryEngine::V1::AnswerQueryResponse.new(answer: { answer_text: "An answer" }) }

    before do
      allow(DiscoveryEngine::Answer::Query).to receive(:new).and_return(query)
      allow(query).to receive(:response).and_return(response)
      Rake::Task["generate_answers:raw_response"].reenable
    end

    it "prints the full JSON response" do
      expect { Rake::Task["generate_answers:raw_response"].invoke("my query") }
        .to output("#{JSON.pretty_generate(response.to_h)}\n").to_stdout
    end
  end
end
