require "csv"

module QualityMonitoring
  class DatasetLoader
    attr_reader :file_path, :data

    def initialize(file_path)
      @file_path = file_path
      @data = Hash.new([])

      load_data
    end

  private

    def load_data
      CSV.foreach(file_path, headers: true) do
        query = _1["query"]
        link = _1["link"]

        data[query] += [link]
      end
    end
  end
end
