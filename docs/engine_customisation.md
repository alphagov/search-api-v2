# Engine customisation
Out of the box, using a next-generation semantic search product already gives us improved results
over

## Event ingestion
We capture interaction data from opted in users in Google Analytics. This data is processed and
ingested into Discovery Engine in bulk on a daily basis to help train the model on what content
users are most likely to be looking for.

This is orchestrated by a set of serverless GCP Cloud Functions and associated plumbing in
[search-v2-infrastructure][search-v2-infrastructure].

## Boosting
We apply boosting to documents based on certain criteria. This is a way of asking Discovery Engine
to prioritise some results over others while still optimising for overall relevance.

### Always active
"Always active" boosts are defined as Discovery Engine serving controls. These apply to all searches
regardless of the user's query or other factors and are defined in
[search-v2-infrastructure][search-v2-infrastructure].

We know that certain types of content are much more likely to be useful to the average user than
others, and we want to prioritise them unless their query is extremely specific. For example, a user
searching for "income tax" will be more interested in services and public-facing information around
income tax than internal HMRC manuals.

### Query-time
Some boosts only make sense to apply at the time a query is made. These are defined in this
application as part of the API and include:
- "best bets", which heavily promote one or more specific pieces of content when a user searches for
  a specific search term (see [best_bets.yml](../config/best_bets.yml))
- boosting for news based on recency, to make sure breaking news is promoted and old news is demoted
  (see [news_recency_boost.rb](../app/services/discovery_engine/news_recency_boost.rb))

## Synonyms
As a semantic search engine, Discovery Engine doesn't need as much synonym configuration compared to
a more traditional "bag of words" keyword search engine.

Still, there are certain domain synonyms that we can't expect a general purpose model to know about, so we define a set of synonyms in [search-v2-infrastructure][search-v2-infrastructure].

[search-v2-infrastructure]: https://github.com/alphagov/search-v2-infrastructure
