require "csv"


task traffic_replay: :environment do
  csv_file = "lib/tasks/traffic_replay.csv"

  integration_path = "https://www.integration.publishing.service.gov.uk/api"
  paths = CSV.read(csv_file)
  paths.each do |row|
    url = "#{integration_path}#{row.first}"
    puts url
    r = Faraday.get(url)
    puts r.status
  end
end