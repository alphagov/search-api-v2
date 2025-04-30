# Search autocomplete
We use Vertex AI Search's [built-in autocomplete functionality][vais-ac] to provide our users with
helpful suggestions to complete their query as they type in search fields.

Search API v2 provides an API to return suggestions, which the [`search_with_autocomplete`
component][component] in frontend rendering apps accesses through a [proxy endpoint][ff-proxy] on
Finder Frontend. Other internal clients and the GOV.UK app may access it directly or through an API
gateway.

## Update denylist
We use a denylist to avoid the autocomplete returning suggestions that are not suitable or helpful.

Search Admin provides a UI to [manage entries on the denylist][search-admin-denylist].

If there are problems updating the denylist we can consider [disabling the autocomplete
feature](#disable-search-autocomplete) temporarily to provide time to resolve the problem.

## Disable search autocomplete
If poor suggestions are shown to users that cannot be mitigated through the denylist, or there is a
problem updating the denylist, or autocomplete needs to be turned off for another reason, the
`ENABLE_AUTOCOMPLETE` feature flag environment variable for Search API v2 can be turned off.

This will cause an empty array of suggestions to be returned to all clients (web or otherwise).

1. Open the appropriate `values-<environment>.yaml` file from GOV.UK Helm Charts, for example
   [values-production.yaml][]
1. Set `ENABLE_AUTOCOMPLETE` in `extraEnv` to `false`
1. Open a PR to apply the change
1. Once merged, a new deployment will be created for Search API v2 and no suggestions will be
   returned

[component]: https://components.publishing.service.gov.uk/component-guide/search_with_autocomplete
[ff-proxy]: https://github.com/alphagov/finder-frontend/blob/main/app/controllers/api/autocompletes_controller.rb
[vais-ac]: https://cloud.google.com/generative-ai-app-builder/docs/configure-autocomplete
[values-production.yaml]: https://github.com/alphagov/govuk-helm-charts/blob/main/charts/app-config/values-production.yaml
[search-admin-denylist]: https://search-admin.publishing.service.gov.uk/completion_denylist_entries
