# Represents a user's search query that can be executed against Discovery Engine
class Query
  def initialize(
    repository_class: Rails.configuration.repository_class
  )
    @repository = repository_class.new
  end

  def result_set
    res = repository.search(nil)

    ResultSet.new(
      results: res.results,
      total: res.total,
      start: 0,
    )
  end

private

  attr_reader :repository
end
