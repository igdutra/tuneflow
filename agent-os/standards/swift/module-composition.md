# Module Composition Standard

## Architecture Overview

![Module dependency diagram](tune_modules.png)

The diagram shows the four modules and the direction of their dependencies. Every arrow points **toward** `TuneDomain` — the module that owns all protocols and domain models. This is the key invariant of the design.

The diagram also reveals **why `Domain` must be its own module** (not a folder inside the app target). If `SongRepository` lived in the app target, `TuneAPI` would have to import the app to conform to it — a circular dependency. Extracting `TuneDomain` into a standalone module that both `TuneAPI` and `TuneCache` can import independently is what makes the whole graph cycle-free.

---

## Layer Names (TuneFlow)

| Layer | Location | Responsibility |
|---|---|---|
| `TuneFlowApp` | App target — `TuneFlowApp.swift` | Composition root; wires the live dependency graph |
| `TuneUI` | App target — `TuneUI/` | ViewModels, Views, Composers |
| `TuneDomain` | `Packages/TuneDomain` | Protocols (repositories, caches, services), domain models, use cases — **separate Swift Package** |
| `TuneCache` | App target — `TuneCache/` | SwiftData store, stored models, cache mappers |
| `TuneAPI` | `Packages/TuneAPI` | HTTP client, remote DTOs, network mappers — **separate Swift Package** |

> Both `TuneAPI` and `TuneDomain` are local Swift Packages so their tests run on macOS directly via `swift test` without the simulator.

**Why `TuneDomain` must be a separate package, not a folder in the app target:**
`TuneAPI` is a Swift Package. Swift Packages cannot import the app target that depends on them — that would be circular. If `SongRepository` lived in the app target and `TuneAPI` needed to conform to it, `TuneAPI` would have to import the app. That is impossible. `TuneDomain` must be a standalone package that both `TuneAPI` and `TuneCache` can import independently.

---

## Dependency Rules

Hard rules — never cross these:

- `TuneUI` must not import `TuneAPI`
- `TuneUI` must not know about SwiftData models
- `TuneUI` must not call `URLSession` directly
- `TuneAPI` must not import `SwiftUI`
- `TuneAPI` must not import the app target — it conforms to `TuneDomain` protocols, not app protocols
- `TuneCache` must not depend on screen types
- `TuneDomain` must not depend on Apple UI frameworks
- `TuneDomain` must not import `TuneAPI` or `TuneCache` — it is the shared foundation, not a consumer

---

## Composition Root

`TuneFlowApp` IS the composition root. It is the only place that imports all modules and wires them together.

```swift
@main
struct TuneFlowApp: App {
    // Infra
    private let httpClient = URLSessionHTTPClient()       // TuneAPI
    private let songCacheStore = SwiftDataSongCacheStore() // TuneCache

    // TuneCache layer
    private lazy var songCache = LocalSongCacheLoader(
        store: songCacheStore,
        mapper: SongCacheMapper.self
    )

    // Repository: TuneAPI conformance to TuneDomain.SongRepository, decorated with cache
    private lazy var songRepository: SongRepository = RemoteSongRepository(
        url: iTunesSearchURL,
        client: httpClient,
        cache: songCache,
        mapper: RemoteSongMapper.map
    )

    var body: some Scene {
        WindowGroup {
            SongsComposer.compose(songRepository: songRepository)
        }
    }
}
```

Rules:
- inject everything through initializers
- keep fallback and caching policy in composition, not in views or repositories
- if wiring grows noisy, wrap it in factory methods on `TuneFlowApp` — a separate `AppContainer` type is optional

---

## Repository vs Service

- Use `Repository` for app-facing data access (load/persist domain models)
- Use `Service` for operations not primarily about data access (e.g., audio playback)

---

## Domain Models and DTOs

Two distinct model layers exist — both map down to domain models at their respective boundaries:

```
TuneAPI layer:     RemoteSongDTO  →  (mapper)  →  Song       (TuneDomain)
Cache layer:       StoredSong     →  (mapper)  →  Song       (TuneDomain)
```

**Domain models** (`Song`, `Album`) are the only models that cross layer boundaries upward. They live in `TuneDomain` and are imported by all layers that need them.

```swift
// TuneDomain/Models/Song.swift
public struct Song: Sendable, Equatable {
    public let id: Int
    public let trackName: String
    public let artistName: String
    public let albumName: String
    public let artworkURL: URL
    public let previewURL: URL?
    public let trackNumber: Int?
}

public struct LocalSongCache: Sendable, Equatable {
    public let songs: [Song]
    public let timestamp: Date
}
```

---

## Protocol Boundaries

### Domain-facing repositories — defined in `TuneDomain`, implemented in `TuneAPI` / `TuneCache`

```swift
// TuneDomain/Repositories/SongRepository.swift
public protocol SongRepository: Sendable {
    func search(query: String, limit: Int, offset: Int) async throws -> [Song]
    func fetchAlbum(collectionId: Int) async throws -> [Song]
}

// TuneDomain/Repositories/RecentlyPlayedRepository.swift
public protocol RecentlyPlayedRepository: Sendable {
    func save(_ song: Song) async throws
    func loadRecent(limit: Int) async throws -> [Song]
}
```

Both protocols live in `TuneDomain`. `TuneAPI` imports `TuneDomain` and provides the remote conformance. `TuneCache` imports `TuneDomain` and provides the local conformance. `TuneUI` imports `TuneDomain` and depends only on the protocols — never on concrete types.

### Network infra interface — defined and used inside `TuneAPI` only

```swift
// TuneAPI/HTTPClient.swift — infra only, never exposed upward
public protocol HTTPClient: Sendable {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}
```

This protocol is an internal seam for testability inside `TuneAPI`. It does not belong in `TuneDomain` because no other layer needs to know about HTTP.

### Cache interfaces — two levels

```swift
// TuneDomain/Cache/SongCache.swift — exposed to composition root
public protocol SongCache: Sendable {
    func save(_ cache: LocalSongCache) async throws
    func load() async throws -> LocalSongCache?
}

// TuneCache/Store/SongCacheStore.swift — infra, used only inside TuneCache
public protocol SongCacheStore: Sendable {
    func insert(_ cache: StoredSongCache) async throws
    func retrieve() async throws -> StoredSongCache?
    func deleteAll() async throws
}
```

`SongCache` is the domain-facing abstraction wired by the composition root. `SongCacheStore` is an internal seam inside `TuneCache` for SwiftData testability.

### Audio playback (service, not repository)

```swift
// TuneDomain/Services/AudioPlayer.swift
public protocol AudioPlayer: Sendable {
    func play(url: URL) async throws
    func pause()
    func seek(to time: TimeInterval)
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
}
```

---

## Mapper Strategy

Mappers are required at both `TuneAPI` and `TuneCache` boundaries. They are pure functions — no test doubles needed, test them directly.

```
TuneAPI:  Data + HTTPURLResponse  →  RemoteSongMapper  →  [Song]
TuneCache: StoredSongCache        →  SongCacheMapper   →  LocalSongCache
```

Rules:
- DTOs (`RemoteSongDTO`) stay inside `TuneAPI` — never leak out
- Stored models (`StoredSong`) stay inside `TuneCache` — never leak out
- Domain models (`Song`, `Album`) cross layer boundaries upward
- Ordering rules (e.g. `sortIndex`) live inside the cache mapper

```swift
// TuneAPI
enum RemoteSongMapper {
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [Song] {
        // validate status
        // decode RemoteSongDTO array
        // map each DTO → Song
    }
}

// TuneCache
enum SongCacheMapper {
    static func toLocal(from stored: StoredSongCache) -> LocalSongCache {
        LocalSongCache(
            songs: stored.items
                .sorted { $0.sortIndex < $1.sortIndex }
                .map(toSong(from:)),
            timestamp: stored.timestamp
        )
    }

    static func toStored(from local: LocalSongCache) -> StoredSongCache {
        StoredSongCache(
            items: local.songs.enumerated().map { index, song in
                StoredSong(song: song, sortIndex: index)
            },
            timestamp: local.timestamp
        )
    }
}
```

---

## Feature Composers

Each screen gets a dedicated `Composer` that assembles its view and view model. Composers live in `TuneUI/Composers/`. They receive `TuneDomain` protocols, never concrete types from `TuneAPI` or `TuneCache`.

```swift
/// Centralizes Songs screen wiring.
@MainActor
public enum SongsComposer {
    public static func compose(songRepository: SongRepository) -> some View {
        let searchUseCase = SearchSongsUseCase(repository: songRepository)
        let recentUseCase = LoadRecentSongsUseCase(repository: songRepository)
        let viewModel = SongsViewModel(
            searchUseCase: searchUseCase,
            recentSongsUseCase: recentUseCase
        )
        return SongsView(viewModel: viewModel)
    }
}

/// Centralizes Player screen wiring.
@MainActor
public enum PlayerComposer {
    public static func compose(
        song: Song,
        queue: [Song],
        songRepository: SongRepository,
        audioPlayer: AudioPlayer,
        recentlyPlayedRepository: RecentlyPlayedRepository
    ) -> some View {
        let playUseCase = PlaySongUseCase(
            audioPlayer: audioPlayer,
            recentlyPlayedRepository: recentlyPlayedRepository
        )
        let viewModel = PlayerViewModel(
            song: song,
            queue: queue,
            playUseCase: playUseCase,
            songRepository: songRepository
        )
        return PlayerView(viewModel: viewModel)
    }
}

/// Centralizes Album screen wiring.
@MainActor
public enum AlbumComposer {
    public static func compose(
        collectionId: Int,
        songRepository: SongRepository
    ) -> some View {
        let fetchUseCase = FetchAlbumUseCase(repository: songRepository)
        let viewModel = AlbumViewModel(
            collectionId: collectionId,
            fetchAlbumUseCase: fetchUseCase
        )
        return AlbumView(viewModel: viewModel)
    }
}
```

Rules:
- composers assemble views and view models — no business logic
- composers accept `TuneDomain` protocols only — never concrete types from `TuneAPI` or `TuneCache`
- helper factories are fine when wiring gets noisy
- views render state and forward actions
- view models own `Task`-based async work

---

## Testing Boundaries

- Test `SongRepository`, `SongCache`, `SongCacheStore`, and `HTTPClient` conformances separately
- Spy on `TuneDomain` protocols in `TuneUI` tests — never on concrete types
- Test mappers directly — pure functions, no doubles needed
- Do not rely on end-to-end tests to validate layer boundaries
- `TuneAPI` and `TuneDomain` tests run on macOS via `swift test` — no simulator required
