# References for Network Layer

## Similar Implementations

### URLProtocolStub (XCTest reference)

- **Location:** Provided by user in shaping conversation (not in codebase)
- **Relevance:** Testing pattern for `URLSessionHTTPClient` — intercepts URLSession requests at the protocol level to stub responses without hitting the network
- **Key patterns:**
  - `URLProtocolStub` subclass with static stub/capture methods
  - `startInterceptingRequests()` / `stopInterceptingRequests()` for setup/teardown
  - Request capture via closure for verifying HTTP method and URL
  - Must be adapted from XCTest to Swift Testing (setUp/tearDown → per-test or `.serialized` trait)

### Essential Developer Modular Architecture Diagram

- **Location:** Provided by user as image in shaping conversation
- **Relevance:** Defines the modular boundary pattern this spec follows
- **Key patterns:**
  - **Feed Feature module** (shared domain) = our `TuneDomain` — holds `<FeedLoader>` protocol + `FeedImage` model
  - **Feed API module** = our `TuneAPI` — holds `RemoteFeedLoader`, `FeedItemsMapper` (internal), `RemoteFeedItem` (internal), `URLSessionHTTPClient`, `<HTTPClient>` protocol
  - **Feed Cache module** = our future `TuneCache`
  - Both API and Cache modules depend **inward** on the shared Feature module, never on each other
  - Composition root (Assembler/Builder/Factory) wires everything at the app level

### iTunes Search API

- **Location:** `https://itunes.apple.com/search`
- **Relevance:** The external API this spec integrates with
- **Key patterns:**
  - GET request with query parameters: `term`, `media=music`, `limit`, `offset`
  - Response envelope: `{ "resultCount": Int, "results": [...] }`
  - Song fields: `trackId`, `trackName`, `artistName`, `collectionName`, `artworkUrl100`, `previewUrl`, `trackNumber`
