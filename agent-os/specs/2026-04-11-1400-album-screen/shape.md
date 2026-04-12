# Track 7 — Album Screen — Shaping Notes

## Scope

Build the Album screen that opens when the user taps "View album" in the More Options sheet. The screen fetches album data from the iTunes Lookup API and displays: large hero artwork, album title, artist name, and a full ordered track list. Navigation is push-based via `AppRoute.album(collectionId:)`.

## Key Decisions

- **`Song` gains `collectionId: Int`** — The iTunes search response already returns `collectionId` per track. It is non-optional because the iTunes API always returns it for song results. This is the minimum field needed to trigger album navigation.
- **`Album` is a new domain entity** — The Album screen needs album-level metadata (title, artist, artwork) plus tracks. Returning `[Song]` would force callers to infer metadata from the first track — fragile and unclear. `Album` is the clean screen boundary.
- **`fetchAlbum(collectionId:)` returns `Album`** — Consistent with above. The repository maps the entire lookup response into a single `Album` value with embedded `tracks: [Song]`.
- **Separate lookup DTOs from search DTOs** — The iTunes lookup response is heterogeneous: one collection-type result (the album) + N song-type results (the tracks). `RemoteAlbumDTO` handles the album result; `RemoteSongDTO` is reused for tracks. `RemoteLookupPage` wraps the mixed array.
- **`AlbumTrack` is NOT introduced** — `Song` already has `trackName`, `artistName`, `trackNumber`, and `artworkURL`. No new type needed for track rows.
- **`lookupBaseURL: URL` added to `RemoteSongRepository.init`** — The lookup endpoint (`/lookup`) differs from the search endpoint (`/search`). Simplest fix: pass a second URL at composition time.
- **`MoreOptionsViewModel` gains `router: AppRouter`** — The `viewAlbum()` stub has been waiting for this. Track 7 wires it: dismiss sheet + push `.album(collectionId:)`.
- **State overlays are TODO comments** — Loading and error overlays follow the same deferred pattern as `SongsView`. The view will include `// TODO: loading overlay` and `// TODO: error overlay` comments but not implement them this track.

## Context

- **Visuals:** `mockups/album.png`
- **References:** `TuneFlow/TuneUI/Songs/SongsViewModel.swift`, `TuneFlow/TuneUI/Navigation/RootView.swift`, `TuneFlow/TuneUI/MoreOptions/MoreOptionsViewModel.swift`, `agent-os/standards/swift/module-composition.md` (AlbumComposer template)
- **Product alignment:** Track 7 of Phase 1 MVP — final screen in the discovery flow

## Standards Applied

- `swift/module-composition` — Album screen wired via `AlbumComposer`; TuneUI never imports TuneAPI; domain models cross layer boundaries upward
- `swift/swiftui` — `@Observable` ViewModel, `State(initialValue:)` ownership, computed display properties, state overlay pattern (as TODOs), `Button` not `onTapGesture`
- `swift/testing` — `@MainActor struct` suite, `makeSUT()` typed tuple, `#expect`, no XCTest
