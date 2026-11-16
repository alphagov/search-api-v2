namespace :generate_answers do
  desc "Reads queries from a CSV (column 'question') and writes Query, Answer, Citations to a CSV"
  task :answers_csv, %i[input_path output_path] => :environment do |_, args|
    input_path = args[:input_path] || abort("Usage: rake generate_answers:answers_csv[input.csv,output.csv]")
    output_path = args[:output_path] || "answers_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.csv"

    puts input_path, output_path

    DiscoveryEngine::Answer::CsvExport.new.export(input_path, output_path)
    puts "Wrote #{output_path}"
  end
end
