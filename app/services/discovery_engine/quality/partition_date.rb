module DiscoveryEngine::Quality
  class PartitionDate
    def self.calculate(month_label: nil, month: nil, year: nil)
      year, month = case month_label
                    when :this_month
                      t = Time.zone.now
                      [t.year, t.month]
                    when :last_month
                      t = Time.zone.now.prev_month
                      [t.year, t.month]
                    else
                      [year, month]
                    end
      Date.new(year, month, 1)
    end
  end
end
