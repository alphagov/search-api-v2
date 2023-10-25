RSpec::Matchers.define :match_json_schema do |expected_schema|
  match do |json_string|
    @errors = expected_schema.validate(json_string).map { _1["error"] }
    @errors.none?
  end

  failure_message do
    "Expected JSON to match schema, but validation failed:\n#{@errors.join("\n")}"
  end

  failure_message_when_negated do
    "Expected JSON not to match schema, but it did."
  end
end
