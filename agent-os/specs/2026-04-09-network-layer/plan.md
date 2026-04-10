# Network Layer (TuneAPI + TuneDomain) — Plan

## Overview

Build the foundation networking infrastructure for TuneFlow as two Swift Packages: `TuneDomain`, which defines the shared song model and repository boundary, and `TuneAPI`, which implements remote song search against the iTunes Search API with pagination, typed errors, and test coverage.

**Standards applied:**

@agent-os/standards/swift/module-composition.md
@agent-os/standards/swift/testing.md

**Reference notes:**

- The Essential Developer modular architecture reference sets the package boundary: `TuneDomain` is the shared inward dependency, while `TuneAPI` keeps transport, DTOs, and mappers internal.
- The provided `URLProtocolStub` reference is the basis for transport-layer tests and must be adapted from XCTest patterns to Swift Testing.
- The iTunes Search API integration uses `https://itunes.apple.com/search` with `term`, `media=music`, `limit`, and `offset` query parameters and a `resultCount`/`results` response envelope.

**Standards notes:**

- `swift/module-composition` requires stable inward-facing boundaries, internal DTOs/mappers, and composition at the app edge.
- `swift/testing` requires struct-based test suites, `makeSUT()` helpers, `#expect`/`#require`, clear spy vs stub usage, and explicit handling of any shared global state.

---

## Stories

### S1: Search songs by text

Given a TuneFlow feature requests songs for a search term
When the remote search succeeds
Then it receives a list of songs with the details needed to present results

### S2: Load additional search results

Given a TuneFlow feature has already loaded search results
When it requests the next page for the same search
Then it receives the next batch of songs for that query

### S3: Show an empty result state

Given a TuneFlow feature searches for songs
When no matching songs are found
Then it receives an empty result set instead of a failure

### S4: Fail gracefully when offline

Given a TuneFlow feature requests songs from the remote service
When the device cannot reach the service
Then the feature receives a recoverable failure it can surface appropriately

### S5: Fail gracefully on unusable server responses

Given a TuneFlow feature requests songs from the remote service
When the service returns an unusable response
Then the feature fails safely instead of receiving unusable song data

---

## Acceptance Criteria

### TuneDomain Package
- [ ] `Packages/TuneDomain/` is a valid Swift Package targeting iOS 26+ and macOS 26+, has no third-party dependencies, and compiles with `swift build`
- [ ] `Song` is a public `struct`, `Sendable`, and `Equatable` with these fields: `id: Int`, `trackName: String`, `artistName: String`, `albumName: String`, `artworkURL: URL`, `previewURL: URL?`, `trackNumber: Int?`
- [ ] `SongRepository` is a public, `Sendable` protocol with `search(query:limit:offset:)` and `fetchAlbum(collectionId:)` methods, and `TuneDomain` exposes only shared protocols and value types with no concrete networking or caching implementations

### HTTP Client
- [ ] `HTTPClient` declares `get(from: URL) async throws -> (Data, HTTPURLResponse)` and is `Sendable`
- [ ] `URLSessionHTTPClient` conforms to `HTTPClient`, performs HTTP GET requests with `URLSession.data(for:)`, and returns the received `(Data, HTTPURLResponse)` tuple unchanged on success
- [ ] `URLSessionHTTPClient` maps `URLSession` request failures to `RemoteSongRepositoryError.connectivity`
- [ ] `TuneAPI` declares its dependency on `TuneDomain` in `Package.swift` and imports only `Foundation` and `TuneDomain` for the networking layer

### RemoteSongRepository & Mapping
- [ ] `RemoteSongRepository` conforms to `SongRepository` and is initialized with an `HTTPClient` and base `URL`
- [ ] `search` builds the iTunes Search API request with `term`, `media=music`, `limit`, and `offset` query parameters
- [ ] `fetchAlbum` builds the appropriate iTunes request for album lookup [NEEDS CLARIFICATION: exact endpoint TBD in Track 7]
- [ ] Remote response DTOs remain internal to `TuneAPI` and are never exposed from the package's public API
- [ ] `RemoteSongMapper` validates a 200 HTTP status before decoding and maps the iTunes response envelope into `[Song]`
- [ ] The mapper correctly populates all `Song` fields from `trackId`, `trackName`, `artistName`, `collectionName`, `artworkUrl100`, `previewUrl`, and `trackNumber`
- [ ] Empty search results return `[]` instead of an error
- [ ] `RemoteSongRepositoryError` is `Equatable`, contains exactly `connectivity` and `invalidData`, and is used for non-200 HTTP responses and malformed JSON failures

### Testing
- [ ] `URLProtocolStub` is adapted for Swift Testing and verifies GET method usage, exact URL delivery, success tuple delivery, and connectivity failure behavior for `URLSessionHTTPClient`; if shared global state is required, the affected tests use `.serialized` with the reason documented
- [ ] `HTTPClientSpy` records requested URLs and can stub success and failure results for repository tests
- [ ] Repository and mapper tests verify no request is made on initialization, correct query URL construction, correct pagination offset handling, valid song mapping, optional field handling, connectivity failure propagation, invalid data failures for non-200 statuses (`199`, `201`, `300`, `400`, `500`), malformed JSON failure, and empty-result success
- [ ] All tests follow the Swift Testing standard: struct suites, `makeSUT()` helpers, `#expect`/`#require`, concrete fixtures, and safe parallel behavior

---

## Tasks

### Task 1: Save Spec Documentation

Create `agent-os/specs/2026-04-09-network-layer/` with:

- **plan.md** — This full plan
- **shape.md** — Shaping notes
- **standards.md** — Relevant standards
- **references.md** — Pointers to reference implementations
- **visuals/** — Any provided visuals

### Task 2: Build the Shared Domain Package

Create `Packages/TuneDomain` as the stable shared boundary for song data and repository behavior so other modules can depend on a single contract.

**Stories:** S1, S2, S3, S4, S5
**ACs:** TuneDomain Package

### Task 3: Build the HTTP Transport Layer

Implement `HTTPClient` and `URLSessionHTTPClient` inside `Packages/TuneAPI`, wire the package dependency on `TuneDomain`, and cover the transport behavior with Swift Testing.

**Stories:** S1, S2, S4, S5
**ACs:** HTTP Client; Testing (`URLProtocolStub` adaptation, serialization rule if needed)

### Task 4: Build Remote Song Search and Mapping

Implement `RemoteSongRepository`, internal DTOs, mapper logic, typed errors, pagination behavior, and the repository/mapper test coverage for successful, empty, and failure cases.

**Stories:** S1, S2, S3, S4, S5
**ACs:** RemoteSongRepository & Mapping; Testing (`HTTPClientSpy`, repository coverage, mapper coverage, Swift Testing conventions)

### Task 5: Validate All ACs

Walk through every acceptance criterion and verify it has been implemented and tested. Flag any gaps.

**ACs:** All
