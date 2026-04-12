# Track 7 — Album Screen — Plan

> Once a task is successfully completed, commit. One commit per task. Single line: task title + key files touched.

## Overview

Implement the Album screen that opens from a selected song context. The screen displays album artwork, title, artist name, and a full ordered track list fetched from the iTunes Lookup API (`/lookup?id=<collectionId>&entity=song`). This requires domain model changes (`collectionId` on `Song`, new `Album` entity), a new repository method, lookup DTOs/mapper, a dedicated view model, and the Album view matching `mockups/album.png`.

**Standards applied:** swift/module-composition, swift/swiftui, swift/testing

---

## Stories

### S1: Album screen opens from song context

Given the user taps "View album" in the More Options sheet
When the sheet dismisses and the album loads
Then the Album screen appears showing the album's artwork, title, and artist name

### S2: Album displays full track list

Given the Album screen has loaded
When the user views the track list
Then all tracks for the album are displayed in their original track order

### S3: Album loading fails

Given the user navigates to an album
When the network is unavailable or the API returns an error
Then the album screen shows an error state (TODO — not implemented this track)

### S4: Album is loading

Given the user navigates to an album
When the album data is being fetched
Then a loading indicator is shown (TODO — not implemented this track)

### S5: Back navigation returns to previous screen

Given the user is on the Album screen
When they tap the back button
Then they return to the previous screen

---

## Acceptance Criteria

### Domain Model
- [ ] `Song` gains `collectionId: Int` field
- [ ] `Album` entity added to `TuneDomain`: `id: Int`, `title: String`, `artistName: String`, `artworkURL: URL`, `tracks: [Song]`
- [ ] `Album` conforms to `Sendable` and `Equatable`
- [ ] `SongRepository` gains `func fetchAlbum(collectionId: Int) async throws -> Album`

### API / Networking
- [ ] `RemoteSongDTO` gains `collectionId: Int` field
- [ ] `RemoteSongMapper.toSong()` maps `collectionId` into `Song`
- [ ] New `RemoteAlbumDTO` for the collection-type result from the lookup response (separate from `RemoteSongDTO`)
- [ ] New `RemoteLookupPage` envelope DTO wrapping `resultCount` and heterogeneous `results` array
- [ ] New `RemoteAlbumMapper` maps lookup response `(Data, HTTPURLResponse)` → `Album`
- [ ] `RemoteAlbumMapper` filters the first collection-type result for album metadata
- [ ] `RemoteAlbumMapper` filters song-type results for tracks, maps each to `Song`, preserves order
- [ ] `RemoteAlbumMapper` throws `invalidData` on non-200, malformed JSON, or missing album result
- [ ] `RemoteSongRepository` implements `fetchAlbum(collectionId:)` building URL: `lookup?id=<collectionId>&entity=song`
- [ ] `RemoteSongRepository.fetchAlbum` uses the same `HTTPClient` pattern as `search`
- [ ] Lookup base URL uses `https://itunes.apple.com/lookup` (different path from `/search`)

### Navigation
- [ ] `AppRoute` gains `.album(collectionId: Int)` case
- [ ] `RootView` handles `.album` destination via `AlbumComposer.compose(...)`
- [ ] `MoreOptionsViewModel` gains `router: AppRouter` dependency
- [ ] `MoreOptionsViewModel.viewAlbum()` dismisses the sheet and pushes `.album(collectionId:)` to the router
- [ ] `MoreOptionsViewModel` reads `collectionId` from the injected `Song`
- [ ] `RootView` sheet case passes router to `MoreOptionsViewModel`
- [ ] `AlbumComposer` receives `collectionId: Int`, `songRepository: any SongRepository`, `router: AppRouter`

### View & ViewModel
- [ ] `AlbumViewModel` is `@MainActor @Observable final class`
- [ ] `AlbumViewModel` owns `state: ViewState` (idle → loading → loaded/error)
- [ ] `AlbumViewModel` owns stored `album: Album?`
- [ ] `AlbumViewModel` exposes computed display properties: `title`, `artistName`, `artworkURL`, `tracks`
- [ ] `AlbumViewModel.load()` calls `repository.fetchAlbum(collectionId:)` and transitions state
- [ ] `AlbumViewModel.load()` is called via `.task` modifier on the view
- [ ] `AlbumView` owns VM via `@State private var viewModel`, injected via `State(initialValue:)` in init
- [ ] `AlbumView` matches mockup: large hero artwork, album title, artist name, vertical track list
- [ ] Track rows show track name and artist name (matching mockup)
- [ ] `AlbumView` includes TODO comments for loading and error overlays (same pattern as `SongsView`) — not implemented yet:
  - `// TODO: loading overlay — show ProgressView when viewModel.state.isLoading`
  - `// TODO: error overlay — show retry UI when viewModel.state.error != nil`
- [ ] `Button` (not `onTapGesture`) for any interactive elements
- [ ] No business logic in view body

### Testing — TuneAPI Package (`Packages/TuneAPI/Tests/`)
- [ ] `RemoteAlbumMapperTests`: valid lookup JSON with 1 album + N songs → correct `Album` with ordered tracks
- [ ] `RemoteAlbumMapperTests`: non-200 status → throws `invalidData`
- [ ] `RemoteAlbumMapperTests`: malformed JSON → throws `invalidData`
- [ ] `RemoteAlbumMapperTests`: missing album result (only songs) → throws `invalidData`
- [ ] `RemoteAlbumMapperTests`: track order preserved (tracks appear in array order)
- [ ] `RemoteAlbumMapperTests`: `collectionId` mapped correctly on each track
- [ ] `RemoteSongRepositoryTests`: `fetchAlbum` sends correct URL (`lookup?id=123&entity=song`)
- [ ] `RemoteSongRepositoryTests`: `fetchAlbum` connectivity error → throws `.connectivity`
- [ ] `RemoteSongRepositoryTests`: `fetchAlbum` non-200 → throws `.invalidData`
- [ ] Existing search mapper tests updated: `collectionId` mapped correctly from search response

### Testing — App Target (`TuneFlowTests/`)
- [ ] `AlbumViewModelTests`: initial state is `.idle`, `album` is `nil`
- [ ] `AlbumViewModelTests`: `load()` success → state `.loaded`, `album` populated with correct data
- [ ] `AlbumViewModelTests`: `load()` failure → state `.error`, `album` remains `nil`
- [ ] `AlbumViewModelTests`: computed display properties return correct values after load
- [ ] `AlbumViewModelTests`: `load()` passes correct `collectionId` to repository
- [ ] `MoreOptionsViewModelTests`: `viewAlbum()` pushes `.album(collectionId:)` to router path
- [ ] `MoreOptionsViewModelTests`: `viewAlbum()` dismisses the sheet
- [ ] `AppRouterTests`: push `.album(collectionId:)` appends to path
- [ ] `Song+Fixture` updated with `collectionId` parameter
- [ ] `SongRepositorySpy` updated with `fetchAlbum` support

### Non-Goals
- No caching / SwiftData for albums
- No commerce metadata (price, buy links)
- No deep links to album screen
- No genre features
- No player integration from album tracks
- No artwork size upgrading (use artworkUrl100 as-is)

---

## Tasks

### Task 1: Save Spec Documentation ✅

### Task 2: Domain Model Changes — `Song` + `Album` + `SongRepository`

Add `collectionId: Int` to `Song`. Create `Album` entity. Add `fetchAlbum(collectionId:)` to `SongRepository`. Update `Song+Fixture` and `Song+PreviewFixture` with `collectionId`. Update `SongRepositorySpy` with `fetchAlbum` support.

**Stories:** S1, S2
**ACs:** Domain Model (all), Testing — `Song+Fixture` updated, `SongRepositorySpy` updated

### Task 3: Search Mapper — Add `collectionId` to DTO and Mapper

Add `collectionId: Int` to `RemoteSongDTO`. Update `RemoteSongMapper.toSong()`. Update existing search mapper tests.

**Stories:** S1
**ACs:** API/Networking — DTO gains collectionId, mapper maps it. Testing — existing search tests updated.

### Task 4: Lookup DTOs, Mapper, and Repository Method + Tests

Create `RemoteAlbumDTO`, `RemoteLookupPage`, `RemoteAlbumMapper`. Implement `fetchAlbum(collectionId:)` on `RemoteSongRepository` with `lookupBaseURL`. Write all mapper and repository tests.

**Stories:** S1, S2, S3
**ACs:** API/Networking (all remaining), Testing — TuneAPI Package (all)

### Task 5: Navigation — Route, MoreOptionsViewModel wiring, AlbumComposer

Add `.album(collectionId: Int)` to `AppRoute`. Wire `MoreOptionsViewModel` with `router` and implement `viewAlbum()`. Create `AlbumComposer`. Update `RootView`. Update `MoreOptionsViewModelTests` and `AppRouterTests`.

**Stories:** S1, S5
**ACs:** Navigation (all), Testing — App Target (MoreOptionsVM tests, AppRouter tests)

### Task 6: AlbumViewModel + Tests

Create `AlbumViewModel` with `load()`, state management, computed display properties. Write all view model tests. Create `Album+Fixture`.

**Stories:** S1, S2, S3, S4
**ACs:** View & ViewModel (VM-related), Testing — App Target (AlbumVM tests)

### Task 7: AlbumView

Create `AlbumView` matching the mockup: hero artwork, album title, artist name, vertical track list with track rows. Add TODO comments for loading and error overlays — not implemented this track.

**Stories:** S1, S2, S3, S4, S5
**ACs:** View & ViewModel (view-related)

### Task 8: Validate All ACs

Walk through every acceptance criterion and verify it has been implemented and tested. Run `swift test` in `Packages/TuneAPI`. List `xcodebuild test` commands for the user to run manually.

**ACs:** All
