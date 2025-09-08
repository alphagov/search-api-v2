# search-api-v2
API and synchronisation worker for general site search on GOV.UK

This application powers the new site search for GOV.UK using Google Cloud Platform (GCP)'s [Vertex
AI Search][vertex-docs] ("Discovery Engine") product as its underlying search engine. It provides
two core pieces of functionality:
- An API that is "minimally compatible" with the existing `search-api` REST interface to the extent
  necessary to power the ["site search" (`/search/all`) finder][search-all-finder].
- A synchonisation worker that receives content updates from the Publishing API message queue and
  updates the Discovery Engine dataset accordingly

## Local development
The official way of running this application locally is through [GOV.UK Docker][govuk-docker], where
a project is defined for it. Because this application is deeply integrated with a SaaS product, you
will have to have access to a GCP Discovery Engine engine to be able to do anything more meaningful
than running the test suite. `govuk-docker` will do this for you by configuring the environment to
point to integration. If you want to run the application without GOV.UK Docker, you can reference
the required [environment variables][env] from there.

You can run the application from within the `govuk-docker` repository directory as follows:

### Building search-api-v2
```bash
make search-api-v2
```

### Running search-api-v2

```bash
gcloud auth application-default login
govuk-docker up -d search-api-v2-app
```

### Running tests

```bash
govuk-docker run search-api-v2-lite bundle exec rake
```

### Running document sync

Running the document sync worker locally requires setting up of rabbitmq. The `document-sync-worker` stack
exists to do this conveniently and can be run as follows:

```bash
govuk-docker run search-api-v2-document-sync-worker bundle exec rake document_sync_worker:run
```

### Running other rake tasks

Other rake tasks (including evaluations related rask tasks) require connecting to the integration environment. 
The `task-runner` stack has been created to do this with minimal dependencies and can be run as follows:

```bash
govuk-docker run search-api-v2-task-runner bundle exec rake [relevant-rake-task]
```

Alternatively, you can run the `lite` stack, setting additional environment variables to point to integration:

```bash
govuk-docker run search-api-v2-lite env GOOGLE_CLOUD_PROJECT_ID="780375417592" DISCOVERY_ENGINE_DEFAULT_COLLECTION_NAME="projects/780375417592/locations/global/collections/default_collection" DISCOVERY_ENGINE_DEFAULT_LOCATION_NAME="projects/780375417592/locations/global" bundle exec rake [relevant-rake-task]`
```

Note that when rake tasks are run locally, no metrics will be pushed to Prometheus. This is because the
Prometheus push gateway is local to the cluster in integration, staging or production. If you need metrics
to be pushed to Prometheus, run the task in the relevant cluster.

## Design goals and `search-api-v2` vs `search-api`
Our primary product goal was to improve the quality of search results for the majority of GOV.UK
users.

The existing search powers a significant number of use cases within GOV.UK, including numerous
user-facing "finder" pages handled by [Finder Frontend][finder-frontend] (among them the
`/search/all` finder that handles _the_ main search page which we usually refer to as "site
search"), but also acts as a very general "everything but the kitchen sink" API for retrieving
content by a set of criteria.

We established that attempting to migrate all of these use cases with over a decade of accumulated
logic and edge cases would distract us from our primary goal and be a poor fit for a next-generation
search product anyway (the overwhelming majority of non-"site search" queries being trivial content
retrieval filtered by certain attributes that could be handled by a relational database).

We therefore made a tactical decision to focus on "site search" only and find the minimal subset of
the existing API contract that is necessary to render search results in this context, and update
[Finder Frontend][finder-frontend] to call our new application if and only if the user is using the
general "site search" finder.

Nothing in this application precludes more use cases being migrated to it in the future, but for the
time being, it is intentionally not a complete replacement for [Search API][search-api] (despite the
"v2" name).

See [Search API compatibility](docs/search_api_compatibility.md) for more information about our
compatibility design choices.

## "Vertex" vs "Discovery Engine"
The marketing name of the search product we use (_Google Vertex AI Search and Conversation_) has
undergone several changes while this application was first developed, and some concepts have
different naming in the Google Cloud Platform UI compared to the actual underlying APIs themselves.

We have chosen to exclusively use the more stable API naming (_Discovery Engine_, _engine_ instead
of _app_, etc.) throughout the codebase and documentation to avoid having to rename things as the
product reached general availability, but you may see the terms "Vertex" or "Vertex Search" as well
as some other marketing terms used in some project artefacts.

## Related projects
- [`finder-frontend`][finder-frontend]: Displays results from this application's API depending on
      the "finder" in use and some other conditions
- [`search-api`][search-api]: The original Search API, a subset of which this application's API
      replicates
- [`search-v2-infrastructure`][search-v2-infrastructure]: Provisions infrastructure for Discovery
      Engine including cloud resources and event ingestion for continuous training of the search
      engine
- [`search-v2-evaluator`][search-v2-evaluator]: Internal tool to test and rate search results


[vertex-docs]: https://cloud.google.com/generative-ai-app-builder/docs/introduction
[search-all-finder]: https://www.gov.uk/search/all
[govuk-docker]: https://github.com/alphagov/govuk-docker
[env]: https://github.com/alphagov/govuk-docker/blob/main/projects/search-api-v2/docker-compose.yml
[finder-frontend]: https://github.com/alphagov/finder-frontend
[search-api]: https://github.com/alphagov/search-api
[search-v2-infrastructure]: https://github.com/alphagov/search-v2-infrastructure
[search-v2-evaluator]: https://github.com/alphagov/search-v2-evaluator
