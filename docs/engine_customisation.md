# Engine customisation
Out of the box, using a next-generation semantic search product already gives us improved results
over the previous Opensearch stack. On top of this, there are ways we tailor search to improve the 
relevance of results for our users.

## Event ingestion
We capture interaction data from opted-in users in Google Analytics. This data is processed and
ingested into Discovery Engine in bulk multiple times per day to help train the model on what content
users are most likely to be looking for.

The happens via a multistep process:

1. GA4 user interaction data is processed overnight by the existing GOV.UK analytics pipeline and ingested into GCP BigQuery.
2. The interaction data is transformed, via [Dataform pipelines][dataform-pipelines], into a [format][user-event-schemas] that can be ingested by Discovery Engine.
3. The transformed data is [imported into Discovery Engine][import-user-events-docs] as "user events", via automated [Rake tasks][import-rake-tasks].

Discovery Engine adjusts the internal ranking model for the engine based on these user events (and some data from its own proprietary search and internet analytics data).

We import a set of complete data from the previous day, every day [just after midday][daily-import]. To reduce the latency 
of user event data being made available to the models, four times a day we also import (imperfect) [intraday data][intraday-import] for the current day.
The Dataform pipelines that transform the data before ingestion run on a [similar schedule][dataform-schedule].

## Boosting
We apply boosting to documents based on certain criteria. This is a way of asking Discovery Engine
to prioritise some results over others while still optimising for overall relevance.

### Always active
"Always active" boosts are defined as part of [Discovery Engine serving controls][serving-control-docs]. 
Serving controls apply to all searches regardless of the user's query or other factors. Our default
serving config is defined in [govuk-infrastructure][default-serving-config].

We know that certain types of content are much more likely to be useful to the average user than
others, and we want to prioritise them unless their query is extremely specific. For example, a user
searching for "income tax" will be more interested in services and public-facing information around
income tax than internal HMRC manuals.

### Query-time
Some boosts only make sense to apply at the time a query is made. These are defined as Discovery Engine
["boost specifications"][boost-spec-docs] and include:

- "best bets", which heavily promote one or more specific pieces of content when a user searches for
  a specific search term (see [best_bets.yml](../config/best_bets.yml))
- boosting for news based on recency, to make sure breaking news is promoted and old news is demoted
  (see [news_recency_boost.rb](../app/services/discovery_engine/query/news_recency_boost.rb))

In future work, we may replace the news_recency boost specification with a boost control for [freshness][freshness-boost].

## Synonyms
As a semantic search engine, Discovery Engine doesn't need as much synonym configuration compared to
a more traditional "bag of words" keyword search engine.

Still, there are certain domain synonyms that we can't expect a general purpose model to know about, so we define a set 
of synonyms in the [serving control][synonym-control].

[dataform-pipelines]: https://github.com/alphagov/search-api-v2-dataform
[user-event-schemas]: https://github.com/alphagov/govuk-infrastructure/blob/main/terraform/deployments/search-api-v2/events_ingestion.tf#L38-L114
[import-user-events-docs]: https://docs.cloud.google.com/generative-ai-app-builder/docs/import-user-events
[import-rake-tasks]: https://github.com/alphagov/search-api-v2/blob/main/lib/tasks/user_events.rake#L2-L10
[daily-import]: https://github.com/alphagov/govuk-helm-charts/blob/main/charts/app-config/values-production.yaml#L3074
[intraday-import]: https://github.com/alphagov/govuk-helm-charts/blob/main/charts/app-config/values-production.yaml#L3077
[dataform-schedule]: https://github.com/alphagov/govuk-infrastructure/blob/main/terraform/deployments/search-api-v2/dataform.tf#L62-L92
[serving-control-docs]: https://docs.cloud.google.com/generative-ai-app-builder/docs/configure-serving-controls#about
[default-serving-config]: https://github.com/alphagov/govuk-infrastructure/blob/main/terraform/deployments/search-api-v2/serving_config_global_default.tf
[boost-spec-docs]: https://docs.cloud.google.com/generative-ai-app-builder/docs/boost-search-results
[freshness-boost]: https://docs.cloud.google.com/generative-ai-app-builder/docs/boost-search-results#freshness-boost
[synonym-control]: https://github.com/alphagov/govuk-infrastructure/blob/main/terraform/deployments/search-api-v2/serving_config_global_default.tf#L183-L198