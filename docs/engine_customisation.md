# Engine customisation
Out of the box, using a next-generation semantic search product already gives us improved results
over the previous Opensearch stack.

## Event ingestion
We capture User event data from opted in users in Google Analytics. This is ingested into Discovery Engine in bulk on a daily basis to help train the model on what content users are most likely to be looking for.

The bigquery tables from which we obtain our User event data are configured in [govuk-infrastructure][event-ingestion-link].

The [Import class](/app/services/discovery_engine/user_events/import.rb) is responsible for importing the User event data into DiscoveryEngine, via Google's [UserEventService API][user-event-api-docs]

[user-event-api-docs]: https://cloud.google.com/generative-ai-app-builder/docs/import-user-events

To reduce the latency of User Event data being made available to the models, it's processed and ingested into Discovery Engine as follows:

 - [Once per day at midday][link-to-cron-task-1], we import data for the previous day
 - [4 times per day][link-to-cron-task-2] we import the intraday data for the current day

[event-ingestion-link]: https://github.com/alphagov/govuk-infrastructure/blob/main/terraform/deployments/search-api-v2/events_ingestion.tf
[link-to-cron-task-1]: https://github.com/alphagov/govuk-helm-charts/blob/3662280fc272792/charts/app-config/values-production.yaml#L2971-L2973
[link-to-cron-task-2]: https://github.com/alphagov/govuk-helm-charts/blob/3662280fc27279/charts/app-config/values-production.yaml#L2974-L2976

## Boosting
We apply boosting to documents based on certain criteria. This is a way of asking Discovery Engine
to prioritise some results over others while still optimising for overall relevance.

### Always active
"Always active" boosts are defined as [Discovery Engine serving controls][serving-controls-documentation]. Serving controls apply to all searches
regardless of the user's query or other factors and are defined in our default Serving config,
[serving_config_global_default][serving_config_global_default].

[serving_config_global_default]: https://github.com/alphagov/govuk-infrastructure/blob/main/terraform/deployments/search-api-v2/serving_config_global_default.tf
[serving-controls-documentation]: https://cloud.google.com/generative-ai-app-builder/docs/configure-serving-controls#about

We know that certain types of content are much more likely to be useful to the average user than
others, and we want to prioritise them unless their query is extremely specific. For example, a user
searching for "income tax" will be more interested in services and public-facing information around
income tax than internal HMRC manuals.

### Query-time
Some boosts only make sense to apply at the time the query is made. These are defined as "boost specifications" in this application as part of the API and include:
- "best bets", which heavily promote one or more specific pieces of content when a user searches for
  a specific search term (see [best_bets.yml](../config/best_bets.yml))
- boosting for news based on recency, to make sure breaking news is promoted and old news is demoted
  (see [news_recency_boost.rb](../app/services/discovery_engine/query/news_recency_boost.rb))

In future work, we may replace the news_recency boost specification with a boost control for freshness configured at the config level.

## Synonyms
As a semantic search engine, Discovery Engine doesn't need as much synonym configuration compared to
a more traditional "bag of words" keyword search engine.

Still, there are certain domain synonyms that we can't expect a general purpose model to know about, so we define a set of synonyms in the [serving control][synonym-control].

[synonym-control]: https://github.com/alphagov/govuk-infrastructure/blob/main/terraform/deployments/search-api-v2/serving_config_global_default.tf#L147-L162
