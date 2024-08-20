# Represents a set of query completion results for an autocomplete feature
class CompletionResult
  include ActiveModel::Model

  attr_accessor :suggestions
end
