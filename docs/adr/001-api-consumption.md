# ADR 001: Consume `search-api-v2` directly from Finder Frontend; read from MQ
2023-09-06

## Context
We are building a new API (`search-api-v2`, in this repository) to supplement the existing
`search-api`. Initially, this will only serve the specific use case of "site search" (specifically
the `/search/all` finder as used by `finder-frontend`) and provide a simplified _strict subset_ of
the existing API.

Both the existing and new APIs should be able to be queried by downstream "consumers" (for example,
`finder-frontend`) within the GOV.UK technology landscape and need to ingest content from upstream
"producers" (for example, `whitehall`).

Currently this happens in the following way:
- `finder-frontend` currently exclusively queries the existing `search-api` as its backend and
  doesn't discriminate between different finders
- Content ingestion into the existing `search-api` from upstream content platforms happens in two
  ways with opposite directions, and only the latter can easily be adapted to have multiple
  consumers:
  - a "legacy" REST API (push-based from the upstream platform) used by Whitehall
  - a message queue (pull-based from `search-api` or arbitrary other consumers) used by all other
  	publishing applications

However, as of the recent decomissioning of all frontend functionality in Whitehall, the publishing
message queue does receive updates for _all_ content (content types on the message queue that are
pushed over the legacy API are ignored by the existing `search-api` to avoid duplicate content).

## Considered options
For the interaction with upstream producers, we only considered adapting the existing message queue
exchange into a fanout exchange that can serve multiple listeners (including both the existing
`search-api` and the new `search-api-v2`), as this option is simple, architecturally reasonable and
readily available to us.

For the interaction with downstream consumers, we considered the following options:
- Modify `finder-frontend` to talk to either API depending on which finder is in use
- Deploy a separate version of `finder-frontend` exclusively for use with `search-api-v2`, and route
  the finders that should use the new API to this application instead
- Build a unified adapter API that sits between `finder-frontend` and both search APIs, and route
  traffic to the appropriate API based on search parameters
- Add the ability for either the old or the new API to call out to the respective other one based on
  search parameters, and make it the "primary" API `finder-frontend` talks to

## Decision drivers
- There is a readily available seam in the form of `finder-frontend`'s `Search::Query` service
  object, which has access to the finder currently in use and the running AB tests, which is all the
  information needed to make a routing decision between the two APIs in a couple of lines of code in
  a single place
- If desired in the future, this approach would still allow us to add information about which API to
  use into the content item schema for finders and use that as a migration pattern instead of
  hardcoding a finder path
- Having a separate frontend would still require code changes in, or worse, a semi-permanent
  branching/forking of, `finder-frontend`
- Building an adapter API would add another semi-permanent deployable unit to the technology
  landscape, and the API would immediately need to handle all search traffic, bringing with it a
  high risk of failure and increasing time to MVP
- Making either API call out to the other one would add coupling between them, making future
  migration and decomissioning more complicated and possibly adding a dependency on a brittle legacy
  service

## Decision
We will modify `finder-frontend` to talk to either API depending on which finder is in use,
initially by checking for the path of the finder and AB test values, leaving open the option of
making the decision "smarter" in the future, for example by adding a API version field to the finder
schema.

## Status
Accepted.
