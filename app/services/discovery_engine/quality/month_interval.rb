module DiscoveryEngine::Quality
  MonthInterval = Data.define(:year, :month) do
    def self.previous_month(months_ago = 1)
      date = Time.zone.now.prev_month(months_ago)
      new(date.year, date.month)
    end

    def to_s
      Date.new(year, month).strftime("%Y-%m")
    end

    def first_day_of_month
      Date.new(year, month, 1).strftime("%Y-%m-%d")
    end
  end
end
