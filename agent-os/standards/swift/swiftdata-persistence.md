# SwiftData Persistence Layer

## Core Principle

Use DTOs for SwiftData models, thus not leaking the `import SwiftData`. All domain models and repositories import domain models, not SwiftData DTOs. This enforces the boundary between persistence and business logic.

**Cache Strategy:** Cache is driven by user **playback**, not network responses. Only songs the user plays are persisted. Use `lastPlayedAt` timestamp to power the "recently played" home screen section.

## Model Definition

Use `@Model` macro with explicit attributes and relationships:

```swift
import SwiftData

@Model
public final class StoredSong {
    @Attribute(.unique) var id: String  // e.g. iTunes track ID
    var title: String
    var artist: String
    var url: URL
    
    // Playback tracking — updated when user plays the song
    var lastPlayedAt: Date
    
    // Optional fields have sensible defaults
    var artworkUrl: URL?
    var cachedImageData: Data?
    
    // Parent relationship — many songs belong to one cache container
    var cache: StoredPlayHistory?
    
    init(id: String, title: String, artist: String, url: URL, lastPlayedAt: Date) {
        self.id = id
        self.title = title
        self.artist = artist
        self.url = url
        self.lastPlayedAt = lastPlayedAt
    }
}

// Container for all recently played songs
@Model
public final class StoredPlayHistory {
    @Relationship(deleteRule: .cascade, inverse: \StoredSong.cache)
    var songs: [StoredSong] = []
    
    // Track when this cache was last updated
    var lastUpdatedAt: Date
    
    init(lastUpdatedAt: Date) {
        self.lastUpdatedAt = lastUpdatedAt
    }
}
```

### Rules

- Mark class as `final` — prevents accidental subclassing
- Use `@Attribute(.unique)` for identity fields (prevents duplicates)
- **Cascade relationships:** Use when child lifecycle depends entirely on parent. Child model must be `optional` or have a default value to satisfy cascade rules
- **Non-cascade relationships:** Use `deleteRule: .noAction` when child can exist independently
- **Array relationships:** Use `@Relationship(deleteRule: .cascade, inverse:)` for one-to-many; children must have optional parent reference
- Optional fields (nullable) should have `nil` defaults; required fields go in `init`

## Repository Pattern: @ModelActor

Use `@ModelActor` for thread-safe CRUD operations. The actor owns the `ModelContext` automatically.

```swift
import SwiftData

@ModelActor
public final actor SongRepository: SongRepositoryProtocol {
    
    /// Fetch all recently played songs (ordered by lastPlayedAt, newest first)
    public func recentlyPlayed() async throws -> [Song] {
        let descriptor = FetchDescriptor<StoredPlayHistory>()
        guard let history = try modelContext.fetch(descriptor).first else {
            return []
        }
        
        // Sort by lastPlayedAt descending (newest first)
        let sorted = history.songs.sorted { $0.lastPlayedAt > $1.lastPlayedAt }
        return sorted.map(SongMapper.toDomain(from:))
    }
    
    /// Record a song as played — insert if new, update lastPlayedAt if exists
    public func recordPlayback(_ song: Song) async throws {
        do {
            // Fetch or create the play history container
            let descriptor = FetchDescriptor<StoredPlayHistory>()
            let history = try modelContext.fetch(descriptor).first ?? StoredPlayHistory(lastUpdatedAt: Date())
            
            // Check if song already cached
            let songId = song.id
            if let existing = history.songs.first(where: { $0.id == songId }) {
                existing.lastPlayedAt = Date()
            } else {
                let stored = SongMapper.toStorage(from: song, cache: history)
                history.songs.append(stored)
            }
            
            history.lastUpdatedAt = Date()
            
            if history.id == nil {
                modelContext.insert(history)
            }
            
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
```

### Rules

- `@ModelActor` automatically provides `modelContext` — do not create your own
- Always call `modelContext.save()` after mutations
- On error, call `modelContext.rollback()` before rethrowing (prevents partial state corruption)
- **This project does NOT implement DELETE operations** — focus on playback recording and recently-played queries
- Use `#Predicate` for filtering (e.g., find by ID before updating)
- Use `SortDescriptor` to order results by `lastPlayedAt` (newest first for home screen)
- No `await` suspension points inside operations → no reentrancy issues

## Domain-Storage Boundary: Mapper

Mappers transform between domain models (public, framework-agnostic) and storage models (internal, SwiftData-specific).

```swift
enum SongMapper {
    
    // MARK: - Domain to Storage
    
    static func toStorage(from domain: Song, cache: StoredPlayHistory) -> StoredSong {
        StoredSong(
            id: domain.id,
            title: domain.title,
            artist: domain.artist,
            url: domain.url,
            lastPlayedAt: Date()  // Always set to now when recording playback
        )
    }
    
    // MARK: - Storage to Domain
    
    static func toDomain(from stored: StoredSong) -> Song {
        Song(
            id: stored.id,
            title: stored.title,
            artist: stored.artist,
            url: stored.url
        )
    }
}
```

### Rules

- Use `enum` with static methods only — mappers are stateless
- Domain models never import SwiftData
- Storage models are `internal` or `private` — only repository sees them
- Map at repository boundaries, never in ViewModels

## Testing SwiftData

Create in-memory ModelContainer for tests:

```swift
private extension SongRepositoryTests {
    func makeSUT() throws -> SongRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: StoredSong.self,
            configurations: config
        )
        return SongRepository(modelContainer: container)
    }
}
```

### Rules

- Use `isStoredInMemoryOnly: true` — tests must not touch disk
- Register all `@Model` types in `ModelContainer(for:)`
- Place `makeSUT()` in a `// MARK: - Helpers` section at test file bottom
- Each test gets a fresh container (clean state)
