namespace :user_events do
  desc "Import yesterday's user events from the BigQuery analytics dataset"
  task import_yesterdays_events: :environment do
    DiscoveryEngine::UserEvents::Import.import_all(Time.zone.yesterday)
  end

  desc "Import today's (intraday) user events from the BigQuery analytics dataset"
  task import_intraday_events: :environment do
    DiscoveryEngine::UserEvents::Import.import_all(Time.zone.today)
  end

  desc "Import user events from the BigQuery analytics dataset for a specific date"
  task :import_events_for_date, [:date] => :environment do |_, args|
    date = Time.zone.parse(args[:date]).to_date
    DiscoveryEngine::UserEvents::Import.import_all(date)
  end
end
