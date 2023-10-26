# Search API compatibility
The aim for the initial Search API v2 MVP is to support the minimum subset of the existing Search
API's footprint that is needed to display global "site search" results, i.e. the `/search/all`
finder. As such, we are intentionally not indexing or retrieving additional fields that may be used
by other finders (or other consumers of the API entirely).

## Fields returned
Search API v2 results cover the following subset of the full Search API document schema. As the only
intended consumer of Search API v2 is Finder Frontend, it will ignore the `fields` parameter on
search requests and always return all of the above fields.

### Returned verbatim from the search product
- content_id
- title
- link
- content_purpose_supergroup
- parts
- part_of_taxonomy_tree
- government_name

### Transformed from the data stored in the search product
- _id
  - Legacy Elasticsearch implementaton detail (set to `link` for internal documents, `content_id`
    for external documents)
- description_with_highlighting
  - Always set to plain `description` (as we are not using snippeting yet)
- public_timestamp
  - Integer in the search schema, transformed back to ISO8601
- content_store_document_type
  - Called `document_type` in the schema
- format
  - Legacy field included for compatibility, always equal to `document_type`
- is_historic
  - Integer in the search schema for boosting purposes, transformed back to boolean

### Requested by Finder Frontend but not included in response
These fields are requested by Finder Frontend on search requests, but it then doesn't do anything
meaningful with them (at least not on the `/search/all` finder). They are not returned in the
response.

- popularity
- manual
- organisations
- world_locations
- topical_events
