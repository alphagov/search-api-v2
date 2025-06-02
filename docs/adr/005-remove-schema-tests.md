# ADR 005: Remove schema tests
2025-06-02

## Context
We provide an [explicit schema][schema-doc] for our Vertex AI Search data store. While VAIS
ostensibly accepts schemas in JSON schema format, it does not support the full breadth of JSON
schema features, and extends the format in incompatible ways (for example by providing a `datetime` attribute type that doesn't exist in JSON).

Until now, we have provided the schema as a JSON file in the [GOV.UK Infrastructure][govuk-infra]
repository, and then used the same file in the test suite for the `search-api-v2` application as
part of a "defence in depth" integration test to ensure that for a number of test documents, the
JSON produced conforms to the schema.

This approach has been problematic for a number of reasons:
- The schema needs to be downloaded from a different repository at test runtime, making the tests
  dependent on the network and meaning changes to the schema there can break the tests without
  warning
- We use additional features of JSON schema that VAIS has so far silently ignored, but they seem to
  be adding some incomplete partial support for some features and so the Terraform deployment has
  suddenly started breaking despite no changes to the schema

Given the brittleness of this approach, and the fact that we have not yet encountered any bugs that
it would have caught, we wanted to re-evaluate the need for these tests.

## Considered options
### As now, but changing the Terraform to ensure only the supported subset of schema is used
This would keep the schema tests, at the considerable cost of a complex REST API provider
configuration in `govuk-infrastructure` to exclude all unsupported features.

Given that we think the schema tests provide marginal value at best, and this does not address the
problem of potential future discrepancies between JSON Schema and VAIS that would require yet more
special casing, we believe this does not offer much benefit.

### Keep the schema tests, but maintain a separate copy of the schema in this repository
This would split the schema into two copies: one in `govuk-infrastructure` for Terraform to apply to
VAIS, and one in `search-api-v2` that is used exclusively for the schema tests.

Given that this introduces the significant risk of drift if someone isn't aware the two copies need
to be kept in sync, and that we're already testing the output of the metadata parsing in several
other ways on both a unit and integration level, we believe this does not offer much benefit either.

### Remove the schema tests entirely and simplify schema to only include VAIS-supported features
This would remove the schema tests entirely, and simplify the schema in `govuk-infrastructure` to
only include the features that VAIS supports (possibly even turning it into Terraform instead of an
external JSON file).

We think that this would not significantly increase the risk of bugs in the metadata parsing and
generation slipping through, especially in light of how stable the schema is now, and would reduce
the complexity of the Terraform configuration and the test suite.

## Decision
We've decided to remove the schema tests entirely and simplify the schema to only include
VAIS-supported features.

[schema-doc]: https://cloud.google.com/generative-ai-app-builder/docs/provide-schema
[govuk-infra]: https://github.com/alphagov/govuk-infrastructure/tree/main/terraform/deployments/search-api-v2
