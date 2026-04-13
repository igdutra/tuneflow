# Track 3 — Persistence Layer — Shaping Notes

## Scope

Cache songs that the user plays using SwiftData. Display them on the home screen ordered by most recently played. Only played songs are cached — not search results.

## Decisions

- **Two interface levels** (mirrors `HTTPClient` / `RemoteSongRepository` pattern):
  - `RecentlyPlayedRepository` (TuneDomain) — domain-facing, used by ViewModels
  - `RecentlyPlayedStore` (TuneCache internal) — infra-facing, shields `LocalRecentlyPlayedRepository` from SwiftData
- **No composite pattern** — `AudioPlayerService.play()` takes a URL, not a Song, so a decorator would lose song metadata
- **Save triggered in `PlayerViewModel.onAppear`** — fire-and-forget `Task { try? await repo.save(song) }`; persistence failure must never degrade playback
- **`ModelContainer` created in `TuneFlowApp.init()`** — NOT passed to `.modelContainer()` on the view hierarchy; SwiftData stays invisible to views
- **`TuneCache` is a folder**, not a Swift Package — extractable later without interface changes
- **`import SwiftData` confined to 3 files**: `StoredSong.swift`, `StoredPlayHistory.swift`, `SwiftDataRecentlyPlayedStore.swift`

## Architecture Wiring

```
PlayerViewModel
  → RecentlyPlayedRepository          (TuneDomain protocol)
    ← LocalRecentlyPlayedRepository   (TuneCache, conforms to domain protocol)
      → RecentlyPlayedStore            (TuneCache infra protocol)
        ← SwiftDataRecentlyPlayedStore (@ModelActor, only SwiftData consumer)
```

## Context

- **Visuals:** None
- **References:** `RemoteSongRepository` + `HTTPClient` pattern in `Packages/TuneAPI/` — exact same two-level interface approach applied here
- **Product alignment:** Required feature — "offline-first, recently played on home screen"

## Standards Applied

- `swift/module-composition` — TuneCache folder structure, dependency rules, composition root wiring
- `swift/swiftdata-persistence` — @Model definitions, @ModelActor, mapper enum, in-memory testing
- `swift/testing` — Swift Testing, makeSUT tuple, spy vs stub, @MainActor only when needed
