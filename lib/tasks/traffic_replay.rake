require "csv"
require "faraday"

task traffic_replay: :environment do
  csv_file = "lib/tasks/traffic_replay.csv"
  integration_path = "https://search.integration.publishing.service.gov.uk"
  paths = CSV.read(csv_file)

	conn = Faraday.new(url: integration_path)

  paths.each do |row|
		path = row.first
    url = "#{integration_path}#{path}"
    puts url
    r = conn.get(path)
    puts r.status
  end
end
