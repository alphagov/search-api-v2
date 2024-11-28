namespace :autocomplete do
  desc "Trigger a purge and re-import of the autocomplete denylist"
  task update_denylist: :environment do
    DiscoveryEngine::Autocomplete::UpdateDenylist.new.call
  end
end
