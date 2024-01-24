namespace :quality_monitoring do
  desc "Check result invariants and log and report violations to Sentry"
  task check_result_invariants: :environment do
    violations = QualityMonitoring::CheckResultInvariants.new.violations

    violations.each do |violation|
      Rails.logger.error(<<~MSG)
        Result invariant violated for '#{violation.query}'
        Expected to find link link: #{violation.expected_link}
      MSG
      GovukError.notify(
        "Result invariant violated for '#{violation.query}'",
        extra: violation.to_h,
      )
    end

    Rails.logger.info("Result invariant check complete, #{violations.count} violation(s) found")
  end
end
