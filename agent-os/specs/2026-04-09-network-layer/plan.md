# Network Layer (TuneAPI + TuneDomain) — Plan

## Overview

Build the foundation networking infrastructure for TuneFlow: a shared domain package (`TuneDomain`) holding the `Song` model and `SongRepository` protocol boundary, and the `TuneAPI` package implementing `RemoteSongRepository` with `HTTPClient` abstraction, iTunes Search API integration, pagination, typed errors, and full test coverage.

**Standards applied:**

@agent-os/standards/swift/module-composition.md
@agent-os/standards/swift/testing.md

**iTunes Search API:**
- Base URL: `https://itunes.apple.com/search`
- Query parameters: `term`, `media=music`, `limit`, `offset`
- Response: `{ "resultCount": Int, "results": [RemoteSongDTO] }`

---

## Task 1: Save Spec Documentation

Create `agent-os/specs/2026-04-09-network-layer/` with:

- **plan.md** — This full plan
- **shape.md** — Shaping notes (scope, decisions, context)
- **standards.md** — References to applied standards
- **references.md** — URLProtocolStub reference, Essential Developer diagram

---

## Task 2: TuneDomain Swift Package

Create `Packages/TuneDomain` — the shared domain module. **This package must be as lean as possible:** only protocols and value types. No implementations, no Foundation-heavy imports beyond what value types need.

Both `TuneAPI` and `TuneCache` (future) will depend on this package. Changes here cascade to all dependents — keep it stable.

Contents:
- `Song` domain model (struct, Sendable, Equatable)
- `SongRepository` protocol (Sendable)

### Requirement: Song domain model

Given the app needs a shared representation of a song
When any module imports TuneDomain
Then it has access to `Song` with fields: `id: Int`, `trackName: String`, `artistName: String`, `albumName: String`, `artworkURL: URL`, `previewURL: URL?`, `trackNumber: Int?`

### Requirement: SongRepository protocol boundary

Given TuneAPI and TuneCache both need to conform to a shared contract
When a module imports TuneDomain
Then it can conform to `SongRepository` with `search(query: String, limit: Int, offset: Int) async throws -> [Song]` and `fetchAlbum(collectionId: Int) async throws -> [Song]`

### Acceptance Criteria

- [ ] `Packages/TuneDomain/` is a valid Swift Package (iOS 26+, macOS 26+)
- [ ] `Song` is a public struct, Sendable, Equatable, with all 7 fields
- [ ] `SongRepository` is a public protocol, Sendable, with `search` and `fetchAlbum` methods
- [ ] `search` accepts `query`, `limit`, and `offset` parameters (pagination support)
- [ ] No implementations — only protocols and value types
- [ ] No third-party dependencies
- [ ] Package compiles with `swift build`

---

## Task 3: HTTPClient Protocol & URLSessionHTTPClient

Build the HTTP client abstraction and its URLSession implementation inside `Packages/TuneAPI`. TuneAPI gains a dependency on TuneDomain.

- `HTTPClient` protocol: `get(from: URL) async throws -> (Data, HTTPURLResponse)`
- `URLSessionHTTPClient` conforms using `URLSession.data(for:)`
- Error: maps URLSession failures to connectivity error

### Requirement: GET request execution

Given a valid URL
When the HTTPClient performs a GET request
Then the request is sent as an HTTP GET to the provided URL

### Requirement: Successful response delivery

Given the server returns data and a valid HTTP response
When the HTTPClient completes the request
Then it returns the received `(Data, HTTPURLResponse)` tuple

### Requirement: Connectivity failure

Given the network is unavailable or the request fails
When the HTTPClient attempts a request
Then it throws a connectivity error

### Acceptance Criteria

- [ ] `HTTPClient` protocol declares `get(from: URL) async throws -> (Data, HTTPURLResponse)`
- [ ] `HTTPClient` is `Sendable`
- [ ] `URLSessionHTTPClient` conforms to `HTTPClient` using `URLSession.data(for:)`
- [ ] `URLSessionHTTPClient` maps URLSession errors to `RemoteSongRepositoryError.connectivity`
- [ ] TuneAPI's `Package.swift` declares dependency on TuneDomain
- [ ] No imports beyond Foundation and TuneDomain

---

## Task 4: URLSessionHTTPClient Tests (URLProtocolStub)

Port the URLProtocolStub reference (from XCTest) to Swift Testing.

### Requirement: Performs GET request with correct URL

Given a stubbed URL
When `URLSessionHTTPClient.get(from:)` is called
Then a GET request is sent to that exact URL

### Requirement: Fails on request error

Given the stub is configured with an NSError
When the client performs a request
Then it throws a connectivity error

### Requirement: Delivers data on successful response

Given the stub returns data and a 200 HTTP response
When the client performs a request
Then it returns the data and response tuple

### Acceptance Criteria

- [ ] `URLProtocolStub` ported from XCTest reference, adapted for Swift Testing
- [ ] Test verifies HTTP method is GET
- [ ] Test verifies request URL matches the provided URL
- [ ] Test verifies connectivity error on stub error
- [ ] Test verifies `(Data, HTTPURLResponse)` returned on success
- [ ] Struct suite, `makeSUT()` with SUTBundle, `#expect`/`#require`
- [ ] Tests are parallel-safe — use `.serialized` trait if URLProtocol global state requires it, with documented reason

---

## Task 5: RemoteSongRepository & RemoteSongMapper

Build the iTunes Search API client inside TuneAPI.

**RemoteSongDTO fields** (internal to TuneAPI, maps to `Song` from TuneDomain):

| JSON key | DTO field | Song field | Type |
|---|---|---|---|
| `trackId` | `trackId` | `id` | `Int` |
| `trackName` | `trackName` | `trackName` | `String` |
| `artistName` | `artistName` | `artistName` | `String` |
| `collectionName` | `collectionName` | `albumName` | `String` |
| `artworkUrl100` | `artworkUrl100` | `artworkURL` | `URL` |
| `previewUrl` | `previewUrl` | `previewURL` | `URL?` |
| `trackNumber` | `trackNumber` | `trackNumber` | `Int?` |

**Error enum:**

```swift
public enum RemoteSongRepositoryError: Error, Equatable {
    case connectivity
    case invalidData
}
```

### Requirement: Search songs by query with pagination

Given a search query, limit of 25, and offset of 0
When the repository searches
Then it sends a GET request to `https://itunes.apple.com/search?term=<query>&media=music&limit=25&offset=0`

### Requirement: Paginated search with offset

Given a search query, limit of 25, and offset of 50
When the repository searches for the next page
Then the request URL includes `offset=50`

### Requirement: Map successful response to Song array

Given the API returns 200 with valid JSON containing song results
When the response is mapped via `RemoteSongMapper`
Then it produces `[Song]` with all fields correctly mapped (including optional `previewURL` and `trackNumber`)

### Requirement: Handle non-200 status codes

Given the API returns a non-200 HTTP status
When the response is processed
Then `invalidData` is thrown

### Requirement: Handle invalid JSON

Given the API returns 200 with malformed JSON
When the response is decoded
Then `invalidData` is thrown

### Requirement: Handle empty results

Given the API returns 200 with `{"resultCount": 0, "results": []}`
When the response is mapped
Then an empty `[Song]` array is returned

### Requirement: Connectivity failure passthrough

Given the HTTPClient throws a connectivity error
When the repository attempts a search
Then it throws `connectivity`

### Acceptance Criteria

- [ ] `RemoteSongRepository` conforms to `SongRepository` from TuneDomain
- [ ] Constructor takes `HTTPClient` and base `URL`
- [ ] `search` builds URL with `term`, `media=music`, `limit`, `offset` query parameters
- [ ] `fetchAlbum` builds URL with appropriate iTunes API call [NEEDS CLARIFICATION: exact endpoint TBD in Track 7]
- [ ] `RemoteSongDTO` is `Decodable`, internal to TuneAPI — never public
- [ ] `RemoteSongMapper` maps `(Data, HTTPURLResponse)` -> `[Song]`
- [ ] Mapper validates 200 status before decoding
- [ ] Mapper throws `invalidData` on non-200 or decode failure
- [ ] Empty results returns `[]`, not an error
- [ ] `RemoteSongRepositoryError` has `connectivity` and `invalidData` cases
- [ ] All 7 Song fields mapped correctly, optionals handled

---

## Task 6: RemoteSongRepository & Mapper Tests

Full test coverage using `HTTPClientSpy`.

### Requirement: No request on init

Given a newly created RemoteSongRepository
When no method has been called
Then zero requests are sent to the HTTPClient

### Requirement: Correct search URL with pagination

Given a query "Beatles", limit 25, offset 0
When the repository searches
Then the spy receives a request to the correctly constructed iTunes URL with all query parameters

### Requirement: Correct pagination on subsequent pages

Given a query "Beatles", limit 25, offset 50
When the repository searches for page 3
Then the spy receives a URL with `offset=50`

### Requirement: Delivers songs on valid response

Given the spy returns 200 with valid song JSON
When search completes
Then it returns the mapped `[Song]` array matching the fixture data

### Requirement: Connectivity error on client failure

Given the spy throws an error
When search is attempted
Then `connectivity` is thrown

### Requirement: InvalidData on non-200

Given the spy returns a non-200 status
When the response is processed
Then `invalidData` is thrown

### Requirement: InvalidData on bad JSON

Given the spy returns 200 with invalid JSON
When decoding is attempted
Then `invalidData` is thrown

### Requirement: Empty array on zero results

Given the spy returns 200 with zero results JSON
When mapping completes
Then `[]` is returned

### Acceptance Criteria

- [ ] `HTTPClientSpy` records requested URLs and stubs results/errors
- [ ] Test: no request on init
- [ ] Test: correct URL with `term`, `media`, `limit`, `offset`
- [ ] Test: pagination offset varies correctly
- [ ] Test: `[Song]` mapping from valid JSON fixture
- [ ] Test: connectivity error on spy failure
- [ ] Test: invalidData on non-200 (parameterized: 199, 201, 300, 400, 500)
- [ ] Test: invalidData on malformed JSON with 200
- [ ] Test: empty array on zero results
- [ ] Separate mapper tests: valid mapping, optional field handling, non-200 rejection, invalid JSON
- [ ] All tests: struct suite, `makeSUT()`, spy pattern, `#expect`/`#require`, concrete fixtures
