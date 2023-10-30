# Represents a user's search query that can be executed against Discovery Engine
class Query
  def result_set
    ResultSet.new(
      results: [],
      total: 0,
      start: 0,
    )
  end
end
