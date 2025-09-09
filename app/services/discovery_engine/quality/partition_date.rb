module DiscoveryEngine::Quality
  class PartitionDate
    def initialize(month_label: nil, month: nil, year: nil)
      @month_label = month_label
      @month = month
      @year = year
    end

    def self.calculate
      new(month_label:, month:, year:).calculate
    end

    def calculate
      Date.new(
        date_components.year,
        date_components.month,
        date_components.day,
      )
    end

  private

    attr_reader :month_label, :month, :year

    def date_components
      case month_label

      when :last_month
        DateComponents.last_month
      when :month_before_last
        DateComponents.month_before_last
      else
        DateComponents.new(year, month, 1)
      end
    end
  end

  DateComponents = Data.define(:year, :month, :day) do
    def self.last_month
      date = Time.zone.now.prev_month
      new(date.year, date.month, 1)
    end

    def self.month_before_last
      date = Time.zone.now.prev_month(2)
      new(date.year, date.month, 1)
    end
  end
end
