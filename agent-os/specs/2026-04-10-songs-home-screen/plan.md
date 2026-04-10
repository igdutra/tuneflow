# Track 4 — Screen: Songs (Home) — Plan

> Once a task is successfully completed, commit. One commit per task. Single line: task title + key files touched.

## Overview

Build the first user-facing screen: the Songs home screen. Displays a search bar and paginated song results from the iTunes API. The ViewModel depends only on `SongRepository` (TuneDomain protocol) — no use case layer for now. TuneUI lives in the app target folder (`TuneFlow/TuneUI/`), not a separate package.

**Standards applied:** swift/module-composition, swift/swiftui, swift/testing

**Deferred (out of scope):**
- Recently played section (needs TuneCache / Track 3)
- Pull-to-refresh (roadmap Phase 2)
- Song tap → Player navigation (Track 5)
- "..." button → Bottom Sheet (Track 6)
- `stateOverlay()` view modifier (will be built when error/empty states are polished)

---

## Stories

### S1: Search songs by text

Given the user is on the Songs screen
When they type a search term and tap the keyboard Search button
Then a list of matching songs is displayed with artwork, title, and artist

### S2: Paginated search results

Given search results are displayed
When the user scrolls to the bottom of the current results
Then the next page of results loads and appends to the list

### S3: No results found

Given the user searches for a term
When no matching songs exist
Then the song list is empty (empty state overlay deferred — the list simply shows nothing)

### S4: Search fails due to network error

Given the user searches for songs
When the network is unavailable or the server returns an error
Then the app transitions to an error state with a retry option

### S5: Clear search resets screen

Given the user has search results displayed
When they clear the search text
Then the song list empties and the screen returns to its initial idle state

### S6: New search replaces previous results

Given the user has search results displayed
When they perform a new search with different text
Then the previous results are replaced with the new search results

---

## Acceptance Criteria

### Search & Display
- [ ] Search sends a request with query, limit=10, and offset=0
- [ ] Results display album artwork (50×50, cornerRadius 8), song title (16pt Medium #FFFFFF), and artist name (12pt Regular #737373)
- [ ] Each row has a trailing "..." button (#FFFFFF @ 34% opacity, 44pt tap target) — action is a no-op for now
- [ ] Rows have no separators and no card backgrounds — transparent on #000000
- [ ] Empty search text clears songs and returns state to .idle
- [ ] A new search resets pagination offset to 0 and replaces (not appends) results

### Pagination
- [ ] `loadMore()` appends the next batch when the last item appears on screen
- [ ] Pagination stops when the API returns fewer items than the page size (10)
- [ ] Concurrent `loadMore()` calls are guarded (no duplicate requests while loading)
- [ ] Pagination failure preserves the existing song list (does not overwrite with error)

### ViewModel Architecture
- [ ] `SongsViewModel` is `@MainActor @Observable final class`
- [ ] ViewModel takes `SongRepository` protocol in init — no TuneAPI import
- [ ] `ViewState` enum (.idle, .loading, .loaded, .error) drives overlays only
- [ ] Content stored in `songs: [Song]` property; pagination internals are `@ObservationIgnored`
- [ ] Computed display properties where needed (e.g. `hasResults`)

### View Architecture
- [ ] `SongsView` owns ViewModel via `@State`, injected with `State(initialValue:)`
- [ ] Uses `NavigationStack` — large title "Songs" collapses to inline on scroll (standard iOS behavior)
- [ ] `.searchable(text:prompt:)` for the search bar; `.onSubmit(of: .search)` triggers search
- [ ] Uses `List` with `.plain` style — per DESIGN.md guidance
- [ ] `// TODO` comments for loading, error, and empty state overlays (deferred)
- [ ] Background is pure black (#000000)
- [ ] App forces dark color scheme (`.preferredColorScheme(.dark)`)

### Composition & Wiring
- [ ] `SongsComposer` receives `SongRepository` protocol, creates ViewModel + View
- [ ] `TuneFlowApp` creates `URLSessionHTTPClient` + `RemoteSongRepository`, passes to `SongsComposer`
- [ ] Xcode template code removed (ContentView.swift, Item.swift, SwiftData boilerplate)

### Infrastructure
- [ ] `ViewState` enum in shared TuneUI folder — reusable for all screens
- [ ] `ViewState` has pattern-match helpers (isIdle, isLoading, isLoaded, error) — NOT Equatable
- [ ] `Song` gets `Identifiable` conformance (extension in TuneDomain)

### Testing
- [ ] `SongsViewModelTests` uses Swift Testing struct suite with `@MainActor`
- [ ] `makeSUT()` returns `(sut: SongsViewModel, spy: SongRepositorySpy)`
- [ ] `SongRepositorySpy` records calls and supports stubbing
- [ ] Tests cover: initial state, search success, search failure, empty text clear, pagination append, pagination end (< 10 items), pagination error preserves list, correct parameters passed

---

## Tasks

### Task 1: Save Spec Documentation ✅

### Task 2: ViewState shared infrastructure
Create `TuneFlow/TuneUI/Shared/ViewState.swift`.

### Task 3: Song Identifiable Conformance
Add `extension Song: Identifiable {}` in TuneDomain's Song.swift.

### Task 4: SongsViewModel + Tests
Create `SongsViewModel`, `SongRepositorySpy`, `Song+Fixture`, `SongsViewModelTests`.
**Stories:** S1, S2, S3, S4, S5, S6

### Task 5: SongsView + SongRowView
Create view hierarchy matching mockups per DESIGN.md.
**Stories:** S1, S2, S3

### Task 6: SongsComposer + App Integration
Create `SongsComposer`, rewrite `TuneFlowApp`, delete template code.
**Stories:** S1 end-to-end

### Task 7: Validate All ACs

---

## Verification

**Run these manually (do not auto-execute):**

```
xcodebuild build -scheme TuneFlow -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -scheme TuneFlow -destination 'platform=iOS Simulator,name=iPhone 17'
```

Manual checks:
- Type a search term, tap Search → songs appear with artwork, title, artist
- Scroll to bottom → more results load and append
- Clear search → list empties
- Disconnect network, search → error state visible
