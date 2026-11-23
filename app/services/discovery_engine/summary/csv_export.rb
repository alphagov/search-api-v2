require "csv"

module DiscoveryEngine::Summary
  class CsvExport
    HEADERS = ["Question_id", "Question", "Summary", "Extractive Answers", "Citations"].freeze

    def initialize(logger: $stderr)
      @logger = logger
    end

    def export(input_path, output_path)
      CSV.open(output_path, "w") do |out|
        out << HEADERS
        encoding = File.binread(input_path).force_encoding("UTF-8").valid_encoding? ? "bom|utf-8" : "Windows-1252:UTF-8"

        CSV.foreach(input_path, headers: true, header_converters: :downcase, encoding:).with_index(1) do |row, index|
          question_id = row["question_id"]
          question = row["question"]

          raise "Missing query in CSV data row #{index}" if question.blank?

          logger.puts("Processing query: #{question}")
          out << summary_row(question_id, question)
        end
      end
    end

  private

    attr_reader :logger

    def summary_row(question_id, question)
      query = Query.new(question)
      [question_id,
       question,
       query.summary_text,
       query.extractive_answers.join("\n\n"),
       query.citations.join("\n\n")]
    rescue StandardError => e
      logger.puts("Failed for #{question}: #{e.message}")
      raise
    end
  end
end
