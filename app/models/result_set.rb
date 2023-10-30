# Represents a set of results for a query as expected by Finder Frontend
class ResultSet
  include ActiveModel::Model

  attr_accessor :results, :total, :start
end