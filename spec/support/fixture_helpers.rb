module FixtureHelpers
  # Parses a JSON fixture file and returns its contents as a hash.
  #
  # @param path [String] The path to the JSON fixture file.
  # @return [Hash] The contents of the JSON fixture file as a hash.
  def json_fixture_as_hash(path)
    JSON.parse(file_fixture(path).read)
  end
end
