# ADR 005: Debouncing Publishing API
2024-03-05

## Context
When content is updated in GOV.UK's upstream content management systems (CMSs), its state is
persisted into the core content repositories through the central workflow-as-a-service tool
[Publishing API][publishing-api]. This service always acts as the main gateway for content
publishing, and in addition to persisting content into the repositories, will subsequently notify
downstream apps (such as this one) of changes using a RabbitMQ message queue.

For historical reasons in how upstream CMSs work internally, a single (ostensibly atomic) change to
a piece of content may actually be represented as a series of changes in Publishing API, in turn
triggering several messages in rapid succession to downstream consumers. For example, updating
"links" between different content items involves a separate operation from updating the content of a
page itself.

Currently, this presents two problems for Search API v2:
- Discovery Engine has a strict rate limit on how many times a document can be updated within the
  space of a second (roughly once), which we exceed due to processing several messages
  simultaneously across workers
- Having a high number of workers listening to the message queue leads to potential out-of-order
  processing of messages, meaning that the last update performed upstream isn't necessarily the last
  one to be processed by us

Both of these points have the potential to lead to data integrity issues, with newer content in the
Discovery Engine datastore being overwritten by outdated content (out of order), or newer content
not being written at all (hitting rate limits).

Neither of these problems were encountered with the previous Elasticsearch-based Search API v1, as
it did not have rate limiting, and made use of the messages' payload version and Elasticsearch's
versioning ability to avoid overwriting newer documents with older ones.

## Considered options

Discovery Engine does not offer transactions, document versioning, or atomic read-and-update-if
style operations, which limits our options to:

### Do nothing

Currently, any message coming through from Publishing API triggers an update of the document
directly in Discovery Engine (regardless of the document version or any other workers concurrently
dealing with the same document).

This is not a long-term option, because:
- Having any number of missing or stale documents in search over an extended period of time is
  unacceptable
- The amount of errors is polluting our error management tool (and muting/ignoring them may mask
  future unrelated bugs)

### Reduce worker count to 1 to enfore in-order processing

In theory, limiting incoming content update processing to a single worker in Search API v2 could
bypass this problem, as under those circumstances RabbitMQ will guarantee in-order delivery and the
Discovery Engine API calls would have enough breathing room to not run into rate limiting.

However, this isn't acceptable as:
- we would lose redundancy in case of worker/Kubernetes node failure
- a single worker would struggle to keep up with peak load (or full re-sync scenarios) leading to
  exceeding our desired timeframe of how long it takes for an updated document to be visible in
  search (<1 minute)

### Implement a locking mechanism

A relatively basic locking mechanism using the existing shared Publishing AWS ElastiCache Redis
instance (to be migrated to a separate instance in the long term once Platforms have a plan for
these) as part of the environment would allow us to reach an acceptable level of correctness without
excessive architectural efforts.

For each document, we would keep up to two keys in Redis:
- `lock:<content_id>`: Whether a worker is currently processing the document (key only present if
  locked)
- `latest:<content_id>`: The last successfully processed version for this document within the last
  24 hours, if any (exact expiry TBC)
  - Note: We cannot just rely on the remote document version in Discovery Engine as the document may
    have been deleted as part of a previous operation

Assuming a peak document update load of 100,000 documents in a 24 hour period, and up to 200 bytes
for each set of Redis keys/values including allowance for overhead, we would store a maximum of
20MiB in Redis, meaning a minimally provisioned instance would be sufficient.

If the locking process fails due to Redis being unavailable, we can temporarily fall back onto the
existing "first update wins" behaviour and track the resulting errors, and perform a full resync if
the scale of the downtime is large enough that a significant number of updates failed due to the old
behaviour.

Upon receiving a message, a worker would:
- use the [`redlock-rb` gem][redlock-gem] to acquire a lock of `lock:<content_id>` with a sensible
  timeout
- if the lock currently exists, [wait for it to be available again](#addendum-how-to-wait-for-lock)
- check `latest:<content_id>` to see if a newer message has recently been successfully processed
  - if so, do nothing and go straight to releasing the lock
- process the message (update or delete the document in Discovery Engine)
  - if processing fails, handle as usual (requeue or discard)
  - otherwise use `SET latest:<content_id> <version>` to update the latest processed version
- release the lock

#### Addendum: How to wait for lock

If the lock for a given document is currently held by another worker, we need to wait for that
worker to complete its processing (or timeout) before continuing.

There are broadly two options:
- polling a.k.a. `sleep` in a loop: if the lock key exists, wait for the remaining time on the lock
  (maybe with a random jitter) before retrying
  - very simple to implement but keeps the worker blocked and unable to process other messages in
    the meantime
- put the message on a special RabbitMQ "delay" queue that gets re-queued after a time-to-live using
  a dead letter exchange
  - avoids blocking workers while waiting for a lock to be released, but adds complexity to the
    RabbitMQ configuration (especially given that we need several separate queues to avoid impacting
    other RabbitMQ consumers, and need to configure the worker to listen to several queues)

## Decision
Pending decision, proposed we implement the described locking behaviour with a polling wait for lock
release.

## Status
Pending.

[publishing-api]: https://github.com/alphagov/publishing-api
[redlock-gem]: https://github.com/leandromoreira/redlock-rb
