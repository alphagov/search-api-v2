# ADR 004: Which documents to index
2023-11-02

## Context
Not every document that is on the Publishing API should be searchable. At the moment, documents are
excluded from search for reasons such as:
- They are not in English (the existing search cannot cope well with other languages, and we want to
  replicate the existing behaviour for now until we are ready to iterate)
- They are not "individually identifiable", i.e. they are nested subdocuments of a parent document
  and don't have their own URL
- Their types are explicitly blocklisted from being indexed because having these kinds of documents
  show up in search wouldn't be helpful (e.g. `redirect`s), or their contents are indexed as part of
  a related primary document (e.g. `html_publication`)

## Considered options
We have considered replicating the existing logic as closely as possible, but this is complicated by
the fact that content currently finds its way into search through two separate pathways (Publishing
API message queue and legacy Whitehall push-based API), with the deciding logic residing across
several applications.

We have considered adding a dependency on the existing `search-api`, either in terms of logic or
data ("does this document exist in Elasticsearch?"), but this would add undesirable coupling to the
old API.

Instead, a thorough analysis of existing data and document types across the GOV.UK estate has led us
to simplify the approach to that outlined in "Decision".

## Decision

Content coming through from Publishing API will be indexed if and only if:
- it has a locale of `en`, **and**
- it is addressable (has a `base_path` or `details.url`), **and**
- its document type does not start with "placeholder", **and**
- either of the following apply:
  - its document type is not on an explicit blocklist (based on existing search behaviour), **or**
  - its base_path is on an explicit allowlist (based on existing configuration in `search-api`)

## Status
Accepted.
