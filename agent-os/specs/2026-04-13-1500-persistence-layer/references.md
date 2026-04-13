# References for Track 3 — Persistence Layer

## Similar Implementations

### HTTPClient / RemoteSongRepository (TuneAPI)

- **Location:** `Packages/TuneAPI/Sources/TuneAPI/`
- **Relevance:** The exact same two-level interface pattern this feature uses. `HTTPClient` is the infra protocol that shields `RemoteSongRepository` from `URLSession`. `RecentlyPlayedStore` plays the same role for `LocalRecentlyPlayedRepository`.
- **Key patterns to borrow:**
  - Infra protocol is `internal` to its package/folder — never exposed upward
  - Domain repo conforms to the domain protocol, delegates to infra protocol
  - Spy in tests: `HTTPClientSpy` records calls and stubs results

### SongsViewModel + SongsComposer

- **Location:** `TuneFlow/TuneUI/Songs/SongsViewModel.swift`, `TuneFlow/TuneApp/Composers/SongsComposer.swift`
- **Relevance:** `SongsViewModel` is the host for the new `recentlyPlayedRepository` dependency and `loadRecentlyPlayed()` method. Study existing `search()` / `loadMore()` patterns before adding the recently played section.

### PlayerViewModel + PlayerComposer

- **Location:** `TuneFlow/TuneUI/Player/PlayerViewModel.swift`, `TuneFlow/TuneApp/Composers/PlayerComposer.swift`
- **Relevance:** `onAppear()` is where the save is triggered. Study how `audioService` is currently injected and used — the new `recentlyPlayedRepository` follows the same pattern.

### TuneFlowApp (Composition Root)

- **Location:** `TuneFlow/TuneApp/TuneFlowApp.swift`
- **Relevance:** All wiring happens here. Study how `httpClient`, `songRepository`, and `audioService` are currently constructed and passed to `RootView`. The `ModelContainer` + store + repository chain follows the same initializer-injection pattern.
