# Development Tips
## Generating a Message Queue payload from a publishing-api document
**Problem**: You need a message queue payload for a given document on `publishing-api`, for example
to add a new integration test JSON fixture.

**Solution**: Obtain a Rails console on integration `publishing-api` and execute the following:
```ruby
edition = Document.find_by(content_id: "<CONTENT-UUID>").live
payload = DownstreamPayload.new(edition, "12345").message_queue_payload # "12345" is the payload ID
payload.to_json
```
