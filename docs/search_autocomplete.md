# Search autocomplete
We use Vertex AI Search's [built-in autocomplete functionality][vais-ac] to provide our users with
helpful suggestions to complete their query as they type in search fields.

Search API v2 provides an API to return suggestions, which the [`search_with_autocomplete`
component][component] in frontend rendering apps accesses through a [proxy endpoint][ff-proxy] on
Finder Frontend. Other internal clients and the GOV.UK app may access it directly or through an API
gateway.

## Update denylist
We use a denylist to avoid the autocomplete returning suggestions that are not suitable or helpful.

Updating this list currently requires a manual process until we complete the work to automate it:

1. In a text editor create a new empty file, save this file as `denylist.jsonl` ([JSON Lines
   format][jsonl])
1. Access [the denylist spreadsheet][denylist] and apply the desired changes to the appropriate tab
1. Copy and paste the contents from the "denylist" column **from each of the several tabs** into
   your created `denylist.jsonl` file

Then for each GOV.UK environment of integration, staging and production:

1. Log into [Google Cloud][gcp] and access the `Search API V2 <environment>` project
1. Access "Cloud Storage" > "Buckets" and find the `search-api-v2-<environment>_vais_artifacts`
   bucket
1. Upload the `denylist.jsonl` file to the bucket, replacing the existing file
1. Leave Google Cloud and open your terminal
1. [Log into][kube-auth] the appropriate environment for Kubernetes
1. Run the `rake autocomplete:update_denylist` [rake task][rake-task] for `search-api-v2` to import the file

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
[denylist]: https://docs.google.com/spreadsheets/d/1aA2JapqNt0nu-MiFraP7p9flSDvNQCm0QvSZi2Unw48
[ff-proxy]: https://github.com/alphagov/finder-frontend/blob/main/app/controllers/api/autocompletes_controller.rb
[gcp]: https://docs.publishing.service.gov.uk/manual/google-cloud-platform-gcp.html#gcp-access
[jsonl]: https://jsonlines.org/
[kube-auth]: https://docs.publishing.service.gov.uk/kubernetes/cheatsheet.html#prerequisites
[rake-task]: https://docs.publishing.service.gov.uk/manual/running-rake-tasks.html#run-a-rake-task-on-eks
[vais-ac]: https://cloud.google.com/generative-ai-app-builder/docs/configure-autocomplete
[values-production.yaml]: https://github.com/alphagov/govuk-helm-charts/blob/main/charts/app-config/values-production.yaml
