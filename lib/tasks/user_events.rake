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

  desc "Purge user events that occurred during the final week of the retention period"
  task purge_final_week_of_retention_period: :environment do
    DiscoveryEngine::UserEvents::Purge.purge_final_week_of_retention_period
  end
end
