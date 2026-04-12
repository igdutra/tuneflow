# References for Track 7 — Album Screen

## Similar Implementations

### SongsViewModel — ViewModel shape reference

- **Location:** `TuneFlow/TuneUI/Songs/SongsViewModel.swift`
- **Relevance:** `AlbumViewModel` follows the same shape: `@MainActor @Observable final class`, `ViewState` enum, stored content + computed display properties, intent methods triggering async work via `Task`.
- **Key patterns:** `private(set) var state: ViewState`, `@ObservationIgnored` on internal state.

### SongsComposer — Composer pattern

- **Location:** `TuneFlow/TuneUI/Composers/SongsComposer.swift`
- **Relevance:** `AlbumComposer` follows the same shape: `@MainActor enum`, `static func compose(...)` accepting `TuneDomain` protocols, returning `some View`.

### RemoteSongMapper — Mapper pattern

- **Location:** `Packages/TuneAPI/Sources/TuneAPI/RemoteSongMapper.swift`
- **Relevance:** `RemoteAlbumMapper` follows the same structure: `enum` with a static `map(_:_:)` function, validates status code, decodes envelope, maps DTOs to domain models.

### RemoteSongRepository — Repository pattern

- **Location:** `Packages/TuneAPI/Sources/TuneAPI/RemoteSongRepository.swift`
- **Relevance:** `fetchAlbum(collectionId:)` follows the same pattern: `URLComponents` for URL building, `HTTPClient.get(from:)`, delegates to mapper.

### MoreOptionsViewModel — Navigation trigger

- **Location:** `TuneFlow/TuneUI/MoreOptions/MoreOptionsViewModel.swift`
- **Relevance:** `viewAlbum()` is currently a no-op stub — Track 7 injects `AppRouter` here and implements the navigation.

### RootView — Navigation destination wiring

- **Location:** `TuneFlow/TuneUI/Navigation/RootView.swift`
- **Relevance:** `.navigationDestination(for: AppRoute.self)` switch — add `.album(let collectionId):` case calling `AlbumComposer.compose(...)`.

### RemoteSongRepositoryTests — Repository test pattern

- **Location:** `Packages/TuneAPI/Tests/TuneAPITests/RemoteSongRepositoryTests.swift`
- **Relevance:** `fetchAlbum` repository tests follow the same structure: `HTTPClientSpy`, URL validation, error cases.

### module-composition.md — AlbumComposer template

- **Location:** `agent-os/standards/swift/module-composition.md`
- **Relevance:** The standard already contains the full `AlbumComposer` template. Use it directly.
