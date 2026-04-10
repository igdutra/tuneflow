# Network Layer (TuneAPI + TuneDomain) — Shaping Notes

## Scope

Build the foundation networking infrastructure for TuneFlow as two Swift Packages:

1. **TuneDomain** — Shared domain module holding `Song` model and `SongRepository` protocol. Lean as possible: only protocols and value types. Both TuneAPI and TuneCache (future) depend inward on this.

2. **TuneAPI** — Network layer implementing `RemoteSongRepository` (conforms to `SongRepository`) with `HTTPClient` protocol abstraction, `URLSessionHTTPClient` concrete implementation, iTunes Search API integration, paginated search, typed errors, and JSON-to-domain mapping.

## Decisions

- **`RemoteSongRepository`** not "Loader" — aligns with this project's repository pattern from module-composition standard
- **TuneDomain as separate Swift Package** — enables TuneAPI and TuneCache to import the shared boundary without depending on each other (Essential Developer modular architecture pattern)
- **TuneDomain starts lean** — only `Song` + `SongRepository` for now. Cache protocols added when TuneCache is built (avoids premature abstractions)
- **`fetchAlbum` on SongRepository** — declared but exact iTunes endpoint TBD in Track 7
- **URLProtocolStub** — ported from XCTest reference to Swift Testing; `.serialized` trait if URLProtocol global state requires it
- **Error enum lives in TuneAPI** — `RemoteSongRepositoryError` with `.connectivity` and `.invalidData`

## Context

- **Visuals:** Essential Developer modular architecture diagram (Feed Feature / Feed API / Feed Cache module boundaries)
- **References:** URLProtocolStub from user's prior XCTest implementation
- **Product alignment:** Roadmap Track 2 — Network Layer (Phase 1 MVP)

## Standards Applied

- **swift/module-composition** — Layer names, dependency rules, protocol boundaries, mapper strategy, DTO isolation
- **swift/testing** — Swift Testing struct suites, makeSUT/SUTBundle, spy vs stub, #expect/#require, parameterized tests
