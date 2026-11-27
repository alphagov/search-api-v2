require "csv"
require "stringio"
require "tmpdir"

RSpec.describe DiscoveryEngine::Answer::CsvExport do
  subject(:exporter) { described_class.new(logger:) }

  let(:logger) { StringIO.new }
  let(:query) { instance_double(DiscoveryEngine::Answer::Query) }
  let(:temp_dir) { Dir.mktmpdir }
  let(:input_path) { File.join(temp_dir, "input.csv") }
  let(:output_path) { File.join(temp_dir, "output.csv") }

  after do
    FileUtils.remove_entry(temp_dir)
  end

  before do
    allow(DiscoveryEngine::Answer::Query).to receive(:new).and_return(query)
    allow(query).to receive_messages(
      answer_text: "An answer",
      citations: ["https://www.gov.uk/a", "https://www.gov.uk/b"],
    )
  end

  def export(csv_content)
    File.write(input_path, csv_content)
    exporter.export(input_path, output_path)
    CSV.read(output_path, headers: true)
  end

  it "reads Windows-1252 encoded CSV files" do
    content = "question_id,question\n1,What’s the cost of a passport?\n"
    File.binwrite(input_path, content.encode("Windows-1252"))
    exporter.export(input_path, output_path)
    rows = CSV.read(output_path, headers: true)
    expect(rows.first["question"]).to eq("What’s the cost of a passport?")
  end

  it "exports questions, answers and citations" do
    rows = export(<<~CSV)
      question_id,question
      1,Q1
      2,Q2
    CSV

    expect(rows.headers).to eq(%w[question_id question answer citations])
    expect(rows.map(&:to_h)).to eq([
      {
        "question_id" => "1",
        "question" => "Q1",
        "answer" => "An answer",
        "citations" => "https://www.gov.uk/a\nhttps://www.gov.uk/b",
      },
      {
        "question_id" => "2",
        "question" => "Q2",
        "answer" => "An answer",
        "citations" => "https://www.gov.uk/a\nhttps://www.gov.uk/b",
      },
    ])
  end

  it "raises when a question is missing" do
    expect {
      export(<<~CSV)
        question_id,question
        1,""
      CSV
    }.to raise_error(RuntimeError, "Missing entry in spreadsheet for the question column")
  end

  it "raises when a question ID is missing" do
    expect {
      export(<<~CSV)
        question_id,question
        "",Q1
      CSV
    }.to raise_error(RuntimeError, "Missing entry in spreadsheet for the question_id column")
  end

  it "logs and re-raises errors from answer generation" do
    allow(query).to receive(:answer_text).and_raise(StandardError, "boom")

    expect {
      export(<<~CSV)
        question_id,question
        1,Q1
      CSV
    }.to raise_error(StandardError, "boom")

    expect(logger.string).to include("Failed for 1: Q1: boom")
  end

  it "writes only headers when there are no questions" do
    rows = export("question_id,question\n")

    expect(rows.headers).to eq(%w[question_id question answer citations])
    expect(rows).to be_empty
  end
end
