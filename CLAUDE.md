# TuneFlow

SwiftUI music discovery app for searching, browsing, and previewing tracks via the iTunes Search API.

## Structure

- `TuneFlow/` — SwiftUI app target
  - `TuneApp/` — entry point, DI wiring, composition root
    - `Composers/` — `SongsComposer`, `PlayerComposer`, `AlbumComposer` (one per screen)
    - `Navigation/` — `AppRouter`, `AppRoute`, `AppSheet`
    - `Analytics/` — `InMemoryAnalyticsTracker`, `PlayerEvent`
    - `AVAudioPlayerService/` — `AVAudioPlayerService` (concrete audio implementation)
    - `LogHandling/` — `OSLogger`
  - `TuneUI/` — SwiftUI views and view models
    - `Shared/` — `ViewState`, `View+StateOverlay`, `ErrorView`
    - `Songs/`, `Album/`, `Player/`, `MoreOptions/` — feature screens
  - `TuneCache/` — SwiftData persistence layer
    - `Store/` — `SwiftDataRecentlyPlayedStore` (`@ModelActor`)
    - `Models/` — `StoredSong`, `StoredPlayHistory`
    - `Repositories/` — `LocalRecentlyPlayedRepository`
    - `Mappers/` — `StoredSongMapper`
- `TuneFlowTests/` — app-level tests (Swift Testing)
  - `Helpers/` — Spy objects and fixtures (`SongRepositorySpy`, `AudioPlayerServiceSpy`, etc.)
- `Packages/TuneAPI/` — networking package; hits iTunes Search API, maps responses to domain models
  - `Sources/TuneAPI/` — `RemoteSongRepository`, `URLSessionHTTPClient`, DTOs, mappers
  - `Tests/TuneAPITests/` — unit tests (Swift Testing)
  - `Tests/TuneAPIIntegrationTests/` — integration tests against the real API
- `Packages/TuneDomain/` — pure domain models and repository protocols (`Song`, `Album`, `SongRepository`, `RecentlyPlayedRepository`, `EventTracker`)
- `agent-os/` — AgentOS specs and standards

## Rules

- NEVER edit TuneFlow.xcodeproj/project.pbxproj yourself. When adding new files, simply say at the end which folder and files where added and I'll add them myself.
- You MAY run `swift test` inside any `Packages/` subdirectory (e.g. `cd Packages/TuneAPI && swift test`) to validate package-level tests — these do not require a simulator.
- During the **Validate All ACs** task, do NOT run `xcodebuild build` or `xcodebuild test` for the app scheme — these require a simulator and take too long. Instead, tell the user to run them manually and list the exact commands.
