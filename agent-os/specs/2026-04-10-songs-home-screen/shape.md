# Track 4 — Songs Home Screen — Shaping Notes

## Scope

Build the Songs home screen: search bar, paginated results list, proper MVVM wiring. First screen where the app actually shows real data from the iTunes API.

## Key Decisions

- **TuneUI as an app-target folder** — NOT a separate Swift Package. The standard defines it as a folder inside the main app target. This avoids the circular-dependency problem that required TuneDomain to be a package (TuneAPI needs to import TuneDomain, not the app target).
- **ViewModel takes SongRepository directly** — No use case layer for now. The ViewModel receives the `SongRepository` protocol from TuneDomain. Use cases can be extracted when business logic grows across multiple screens.
- **Native .searchable modifier** — Gives the iOS large-title → inline-title collapse for free, matching both mockup states (songs.png and songs-searchedMinimized.png) without custom implementation.
- **ViewState helpers are pattern-match only** — NOT Equatable. The `.error(Error)` case makes automatic Equatable tricky. Use `isIdle`, `isLoading`, `isLoaded`, `error` computed helpers instead.
- **stateOverlay() modifier deferred** — ViewState enum is created (for ViewModel tests), but the View modifier for rendering loading/error/empty states is a TODO. Overlays will be added when those states are polished (roadmap Phase 2).
- **Page size = 10** — Conservative starting point; easy to bump later.

## Architecture: How TuneUI Connects to TuneAPI

```
TuneFlowApp (composition root)
  ├── imports TuneAPI  → creates URLSessionHTTPClient + RemoteSongRepository
  ├── imports TuneDomain → types SongRepository as protocol
  └── calls SongsComposer.compose(songRepository: SongRepository)
         └── TuneUI/Composers/SongsComposer
               └── SongsViewModel(repository: SongRepository)  ← protocol only
                     └── SongsView(viewModel:)
```

TuneUI files import only `TuneDomain`. The concrete `RemoteSongRepository` never appears in TuneUI.

## Context

- **Visuals:** `mockups/songs.png` (default home), `mockups/songs-searchedMinimized.png` (after search/scroll)
- **References:** HTTPClientSpy pattern (for SongRepositorySpy), Song+Fixture (test data)
- **Product alignment:** Track 4 in Phase 1 MVP — core feature, every decision favors simplicity over extensibility

## Standards Applied

- `swift/module-composition` — TuneUI layer, dependency rules, composer pattern
- `swift/swiftui` — @Observable ViewModel, ViewState, main view ownership, state overlays
- `swift/testing` — struct suites, makeSUT(), spy pattern, @MainActor on VM tests
