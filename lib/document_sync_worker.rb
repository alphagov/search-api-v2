# Gems specific to the document sync worker are in their own group in the Gemfile
Bundler.require(:document_sync_worker)

module DocumentSyncWorker
  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/document_sync_worker", namespace: DocumentSyncWorker)
  loader.setup
end
