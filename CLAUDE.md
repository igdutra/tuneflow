# TuneFlow

SwiftUI music discovery app for searching, browsing, and previewing tracks via the iTunes Search API.

## Structure

- `TuneFlow/` — SwiftUI app target (entry point, views)
- `TuneFlowTests/` — app-level test stubs
- `Packages/TuneAPI/` — networking package; hits iTunes Search API, maps responses to domain models
  - `Sources/TuneAPI/` — `RemoteSongRepository`, `URLSessionHTTPClient`, DTOs, mapper
  - `Tests/TuneAPITests/` — unit tests (Swift Testing)
  - `Tests/TuneAPIIntegrationTests/` — integration tests against the real API
- `Packages/TuneDomain/` — pure domain models and repository protocols (`Song`, `SongRepository`)
- `agent-os/` — AgentOS specs and standards
