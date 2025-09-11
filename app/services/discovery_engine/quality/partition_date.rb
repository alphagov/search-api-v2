module DiscoveryEngine::Quality
  class PartitionDate
    def self.calculate(month_label: nil, month: nil, year: nil)
      year, month = case month_label
                    when :last_month
                      t = Time.zone.now.prev_month
                      [t.year, t.month]
                    when :month_before_last
                      t = Time.zone.now.prev_month(2)
                      [t.year, t.month]
                    else
                      [year, month]
                    end
      Date.new(year, month, 1)
    end
  end
end
