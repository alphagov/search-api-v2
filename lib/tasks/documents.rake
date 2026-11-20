namespace :documents do
  desc "Purge ALL documents from Discovery Engine (destructive!)"
  task purge_all: :environment do
    abort "Cannot purge documents from Discovery Engine in production!" if GovukEnvironment.current == "production"

    DiscoveryEngine::Documents::Purge.new.call
  end
end
