namespace :documents do
  desc "Purge ALL documents from Discovery Engine (destructive!)"
  task purge_all: :environment do
    DiscoveryEngine::Documents::Purge.new.call
  end
end
