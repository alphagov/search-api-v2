require "csv"

module DiscoveryEngine::Answer
  class CsvExport
    HEADERS = %w[question_id question answer citations].freeze

    def initialize(logger: $stderr)
      @logger = logger
    end

    def export(input_path, output_path)
      CSV.open(output_path, "w") do |out|
        out << HEADERS
        encoding = File.binread(input_path).force_encoding("UTF-8").valid_encoding? ? "bom|utf-8" : "Windows-1252:UTF-8"

        CSV.foreach(input_path, headers: true, encoding:) do |row|
          question = row["question"]
          question_id = row["question_id"]
          raise "Missing entry in spreadsheet for the question column" if question.blank?
          raise "Missing entry in spreadsheet for the question_id column" if question_id.blank?

          logger.puts("Processing question_id: #{question_id}, question: #{question}")
          out << answer_row(question_id, question)
        end
      end
    end

  private

    attr_reader :logger

    def answer_row(question_id, question)
      query = Query.new(question)
      [question_id, question, query.answer_text, query.citations.join("\n")]
    rescue StandardError => e
      logger.puts("Failed for #{question_id}: #{question}: #{e.message}")
      raise
    end
  end
end
