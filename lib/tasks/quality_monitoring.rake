namespace :quality_monitoring do
  desc "Runs the invariant dataset and validates 100% recall"
  task assert_invariants: :environment do
    dir = Rails.root.join("config/quality_monitoring_datasets/invariants")
    invariant_dataset_files = Dir.glob("#{dir}/*.csv")

    invariant_dataset_files.each do |file|
      QualityMonitoring::Runner.new(
        file,
        :invariants,
        cutoff: 10,
        report_query_below_score: 1.0,
        judge_by: :recall,
      ).run
    end
  end
end
