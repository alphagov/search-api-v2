namespace :generate_summaries do
  desc "Reads queries from a CSV (column 'query' or 'question') and writes Query, Summary, Extractive Answers and Citations to a CSV"
  task :summaries_csv, %i[input_path output_path] => :environment do |_, args|
    input_path = args[:input_path] || abort("Usage: rake generate_summaries:summaries_csv[input.csv,output.csv]")
    output_path = args[:output_path] || "summaries_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.csv"

    puts input_path, output_path

    DiscoveryEngine::Summary::CsvExport.new.export(input_path, output_path)
    puts "Wrote #{output_path}"
  end

  desc "Outputs the full JSON search summary response for a single query"
  task :raw_response, [:query] => :environment do |_, args|
    query = args[:query] || abort("Usage: rake generate_summaries:raw_response['your query']")
    puts JSON.pretty_generate(DiscoveryEngine::Summary::Query.new(query).response.to_h)
  end
end
