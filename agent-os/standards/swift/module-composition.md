# Module Composition Standard

## Layer Names (TuneFlow)

| Layer | Location | Responsibility |
|---|---|---|
| `TuneFlowApp` | App target — `TuneFlowApp.swift` | Composition root; wires the live dependency graph |
| `TuneUI` | App target — `TuneUI/` | ViewModels, Views, Composers |
| `Domain` | App target — `Domain/` | Protocols (repositories, caches), domain models, use cases |
| `TuneCache` | App target — `TuneCache/` | SwiftData store, stored models, cache mappers |
| `TuneAPI` | `Packages/TuneAPI` | HTTP client, remote DTOs, network mappers — separate Swift Package |

> `TuneAPI` is the network layer. It is a local Swift Package so its tests run on macOS directly via `swift test` without the simulator.

These boundaries live inside one app target (except `TuneAPI`). Separation is enforced through protocols, mappers, and import discipline — not separate build targets.

## Dependency Rules

Hard rules — never cross these:

- `TuneUI` must not import `TuneAPI`
- `TuneUI` must not know about SwiftData models
- `TuneUI` must not call `URLSession` directly
- `TuneAPI` must not import `SwiftUI`
- `TuneCache` must not depend on screen types
- `Domain` must not depend on Apple UI frameworks

## Composition Root

`TuneFlowApp` IS the composition root. Wire dependencies directly in the app struct — no separate `AppContainer` type needed unless wiring grows unwieldy.

```swift
@main
struct TuneFlowApp: App {
    // Infra
    private let httpClient = URLSessionHTTPClient()
    private let songCacheStore = SwiftDataSongCacheStore()

    // TuneCache layer
    private lazy var songCache = LocalSongCacheLoader(
        store: songCacheStore,
        mapper: SongCacheMapper.self
    )

    // Repository (composes remote + cache)
    private lazy var songRepository = RemoteSongRepository(
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
- keep fallback and caching policy in composition, not in views
- if wiring grows noisy, wrap it in factory methods on `TuneFlowApp` — a separate type is optional

## Repository vs Service

- Use `Repository` for app-facing data access (load/persist domain models)
- Use `Service` for operations not primarily about data access (e.g., audio playback)

## Domain Models and DTOs

Two distinct model layers exist — both map down to domain models at their respective boundaries:

```
TuneAPI layer:     RemoteSongDTO  →  (mapper)  →  Song       (domain)
Cache layer:       StoredSong     →  (mapper)  →  Song       (domain)
```

**Domain models** (`Song`, `Album`) are the only models that cross layer boundaries upward.

```swift
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

## Protocol Boundaries Sketch

### Domain-facing repository (exposed upward to `TuneUI`)

```swift
// Domain/Repositories/SongRepository.swift
public protocol SongRepository: Sendable {
    func search(query: String, limit: Int, offset: Int) async throws -> [Song]
    func fetchAlbum(collectionId: Int) async throws -> [Song]
}

// Domain/Repositories/RecentlyPlayedRepository.swift
public protocol RecentlyPlayedRepository: Sendable {
    func save(_ song: Song) async throws
    func loadRecent(limit: Int) async throws -> [Song]
}
```

### Network infra interface (used only inside `TuneAPI`)

```swift
// TuneAPI — infra only, never exposed upward
public protocol HTTPClient: Sendable {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}
```

### Cache interfaces (two levels)

```swift
// Domain/Cache/SongCache.swift — exposed upward to composition root
public protocol SongCache: Sendable {
    func save(_ cache: LocalSongCache) async throws
    func load() async throws -> LocalSongCache?
}

// TuneCache/Store/SongCacheStore.swift — infra, used only inside TuneCache layer
public protocol SongCacheStore: Sendable {
    func insert(_ cache: StoredSongCache) async throws
    func retrieve() async throws -> StoredSongCache?
    func deleteAll() async throws
}
```

### Audio playback (service, not repository)

```swift
// Domain/Services/AudioPlayer.swift
public protocol AudioPlayer: Sendable {
    func play(url: URL) async throws
    func pause()
    func seek(to time: TimeInterval)
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
}
```

## Mapper Strategy

Mappers are required at both `TuneAPI` and `Cache` boundaries.

```
TuneAPI:  Data + HTTPURLResponse  →  RemoteSongMapper  →  [Song]
Cache:    StoredSongCache         →  SongCacheMapper   →  LocalSongCache
```

Rules:
- DTOs (`RemoteSongDTO`) stay inside `TuneAPI` — never leak out
- Stored models (`StoredSong`) stay inside `TuneCache` — never leak out
- Domain models (`Song`, `Album`) cross layer boundaries
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

// Cache
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

## Feature Composers

Each screen or feature gets a dedicated `Composer` that assembles its view and view model. Composers live in `TuneUI/Composers/`.

```swift
/// Centralizes Songs screen wiring in one discoverable place.
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
```

```swift
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
```

```swift
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
- composers may build use cases from injected repositories
- helper factories are fine when wiring gets noisy
- views render state and forward actions
- view models own `Task`-based async work

## Testing Boundaries

- Test `SongRepository`, `SongCache`, `SongCacheStore`, and `HTTPClient` conformances separately
- Spy on domain-facing protocols in `TuneUI` tests
- Test mappers directly (pure functions — no test doubles needed)
- Do not rely on end-to-end tests to validate layer boundaries
