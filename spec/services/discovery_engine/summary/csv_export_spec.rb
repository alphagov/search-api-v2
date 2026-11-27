require "csv"
require "stringio"
require "tmpdir"

RSpec.describe DiscoveryEngine::Summary::CsvExport do
  subject(:exporter) { described_class.new(logger:) }

  let(:logger) { StringIO.new }
  let(:query) { instance_double(DiscoveryEngine::Summary::Query) }
  let(:temp_dir) { Dir.mktmpdir }
  let(:input_path) { File.join(temp_dir, "input.csv") }
  let(:output_path) { File.join(temp_dir, "output.csv") }

  after do
    FileUtils.remove_entry(temp_dir)
  end

  before do
    allow(DiscoveryEngine::Summary::Query).to receive(:new).and_return(query)
    allow(query).to receive_messages(
      summary_text: "A summary [1]",
      extractive_answers: ["First passage", "Second passage"],
      citations: %w[https://www.gov.uk/a https://www.gov.uk/b],
    )
  end

  def export(csv_content)
    File.binwrite(input_path, csv_content)
    exporter.export(input_path, output_path)
    CSV.read(output_path, headers: true)
  end

  it "reads Windows-1252 encoded CSV files with a question column" do
    rows = export("question\nWhat’s the cost of a passport?\n".encode("Windows-1252"))

    expect(rows.first["Question"]).to eq("What’s the cost of a passport?")
  end

  it "exports queries, summaries, extractive answers and citations" do
    rows = export("question_id,question\nid1,Q1\nid2,Q2\n")

    expect(rows.headers).to eq(["Question_id", "Question", "Summary", "Extractive Answers", "Citations"])
    expect(rows.map(&:fields)).to eq([
      ["id1", "Q1", "A summary [1]", "First passage\n\nSecond passage", "https://www.gov.uk/a\n\nhttps://www.gov.uk/b"],
      ["id2", "Q2", "A summary [1]", "First passage\n\nSecond passage", "https://www.gov.uk/a\n\nhttps://www.gov.uk/b"],
    ])
  end

  it "raises when a query is missing" do
    expect { export("query\n\"\"\n") }
      .to raise_error(RuntimeError, "Missing query in CSV data row 1")
  end

  it "logs and re-raises errors from summary generation" do
    allow(query).to receive(:summary_text).and_raise(StandardError, "boom")

    expect { export("question\nQ1\n") }.to raise_error(StandardError, "boom")
    expect(logger.string).to include("Failed for Q1: boom")
  end

  it "writes only headers when there are no queries" do
    rows = export("query\n")

    expect(rows.headers).to eq(["Question_id", "Question", "Summary", "Extractive Answers", "Citations"])
    expect(rows).to be_empty
  end
end
