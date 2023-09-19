# ADR 002: Google Cloud Platform Usage
2023-09-14

## Context
As part GOV.UK site search improvements, there is a need to orchestrate the export, transform and import
of Google Analytics data into a new search engine. 

The search engine doesn't currently support direct import of GA4 format data (though this may become available in future) so requires export into a cut down staged format in BigQuery or Cloud Storage which can them be imported into the search engine.

Cloud libraries provide the mechanisms for exporting BigQuery data and importing the data into the search engine so any code required is predominantly to orchestrate that process.

## Considered options
### Scheduled
![GCP Scheduled](images/002-gcp-scheduled.drawio.svg)
* Cloud Scheduler is used to providec GCP based CRON scheduled triggering. 
* Cloud Functions are used to provide lightweight execution of Python or Ruby code to orchestrate GCP Cloud Libraries for BigQuery export of GA4 data (into staged format expected by the search engine) and search engine import of that data.
### Event Triggered
![GCP Event Triggered](images/002-gcp-event-triggered.drawio.svg)
* Cloud Logging is used to monitor completion GA4 Export to BigQuery.
* PubSub is used for asynch messaging of GA4 data export completion and Staging data completion 
* Cloud Functions are used to provide lightweight execution of Python or Ruby code to orchestrate GCP Cloud Libraries for BigQuery export of GA4 data (into staged format expected by the search engine) and search engine import of that data.
### Workflow
![GCP Workflow](images/002-gcp-workflow.drawio.svg)
* Cloud Composer is used to provide end to end workflow orchestration
## Decision drivers
1. One of the objectives of search improvements is to minimise maintenance overheads and the complexity of managing search so though an event-triggered solution may be more graceful, we don't want to over-engineer a solution which may be more complex to maintain
2. Cost of full blown data workflow services such as Cloud Composer can be significantly more than lightweight options such as Cloud Functions
3. The completion timing of daily GA4 Export is unpredictable so can't be guaranteed to complete
4. Event triggering would support more frequent export/import of data including Intraday GA4 data, minimising the latency for events being imported and available in the search engine
5. The latency requirements of reflecting recent events in the search engine is not near-real time and will ultimately always be dependent on the time the search engine takes to train and tune it's models which may not be in our control 

## Decision
In discussions between @richardTowers and Matt Gregory on 14th Sept 2023 it was agreed to implement Scheduled option with sufficient headroom for GA4 export completion and to use Python for orchestration code due to function and cloud library support

An Event triggered option would be more graceful but potentially over-engineering at this stage based on data import frequency and latency requirements

A full blown workflow approach would be costly and with no existing capability in GOV.UK would likely add to maintenance overheads

## Status
Decided
