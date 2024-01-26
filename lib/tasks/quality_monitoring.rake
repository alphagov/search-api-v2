namespace :quality_monitoring do
  desc "Check result invariants and log and report violations to Sentry"
  task check_result_invariants: :environment do
    violations = QualityMonitoring::CheckResultInvariants.new.violations
    violation_count_text = "#{violations.count} #{'violation'.pluralize(violations.count)}"

    if violations.any?
      violations.each do |violation|
        Rails.logger.error(<<~MSG)
          Result invariant violated for '#{violation.query}'
          Expected to find link: #{violation.expected_link}
        MSG
      end

      GovukError.notify(
        "⚠️ Result invariants check: #{violation_count_text}",
        extra: {
          violations: violations.map { "'#{_1.query}': missing #{_1.expected_link}" }.join("\n"),
        },
      )
    end
    Rails.logger.info("Result invariant check complete, #{violation_count_text} found")
  end
end
