# Track 3 — Persistence Layer — Plan

> Once a task is successfully completed, commit. One commit per task. Single line: task title + key files touched.

## Overview

SwiftData-backed recently-played cache. Only songs the user plays are persisted. Home screen displays them ordered by `lastPlayedAt` descending. Lives in `TuneFlow/TuneCache/` (folder, not package yet). Fully protocol-driven — extractable to a Swift Package later without touching other layers.

**Standards applied:** module-composition, swiftdata-persistence, testing

---

## Gaps Identified

1. `Song.albumName` is non-optional but not in standard's `StoredSong` — add `albumName` field for lossless round-trip.
2. `history.id == nil` check in standard is incorrect — `PersistentIdentifier` is never nil. Fix: always call `modelContext.insert(history)` when creating a new `StoredPlayHistory`.
3. `ModelContainer` must register both types: `ModelContainer(for: StoredSong.self, StoredPlayHistory.self, ...)`.

---

## Stories

### S1: Recently played persists across sessions
Given the user plays a song  
When they close and reopen the app  
Then the song appears in the "Recently Played" section on the home screen

### S2: Recently played section shows most recent songs first
Given the user has played several songs  
When they view the home screen  
Then "Recently Played" lists songs newest first

### S3: Playing a song again updates its position
Given the user has already played Song A and Song B  
When the user plays Song A again  
Then Song A appears at the top with no duplicate entry

### S4: Home screen shows recently played on launch
Given the user has previously played songs  
When the home screen appears  
Then "Recently Played" is populated without requiring a search

### S5: Empty state when no songs have been played
Given the user has never played a song  
When the home screen appears  
Then "Recently Played" section is not shown (no crash)

---

## Acceptance Criteria

### Protocol Layer (TuneDomain)
- [ ] `RecentlyPlayedRepository.swift` added to `Packages/TuneDomain/Sources/TuneDomain/Repositories/`
- [ ] `public protocol RecentlyPlayedRepository: Sendable`
- [ ] `func save(_ song: Song) async throws`
- [ ] `func loadRecent(limit: Int) async throws -> [Song]`
- [ ] No SwiftData import in TuneDomain

### TuneCache Folder Structure
- [ ] `TuneFlow/TuneCache/Models/StoredSong.swift`
- [ ] `TuneFlow/TuneCache/Models/StoredPlayHistory.swift`
- [ ] `TuneFlow/TuneCache/Repositories/RecentlyPlayedStore.swift`
- [ ] `TuneFlow/TuneCache/Repositories/LocalRecentlyPlayedRepository.swift`
- [ ] `TuneFlow/TuneCache/Store/SwiftDataRecentlyPlayedStore.swift`
- [ ] `TuneFlow/TuneCache/Mappers/StoredSongMapper.swift`

### StoredSong Model
- [ ] `@Model final class StoredSong`
- [ ] `@Attribute(.unique) var id: Int`
- [ ] `var title: String`, `artist`, `albumName`, `url: URL`, `lastPlayedAt: Date`
- [ ] `var artworkUrl: URL?`
- [ ] `var cache: StoredPlayHistory?` (optional for cascade rule)

### StoredPlayHistory Model
- [ ] `@Model final class StoredPlayHistory`
- [ ] `@Relationship(deleteRule: .cascade, inverse: \StoredSong.cache) var songs: [StoredSong] = []`
- [ ] `var lastUpdatedAt: Date`

### StoredSongMapper
- [ ] `enum StoredSongMapper` with static methods only
- [ ] `toStorage(from:cache:)` — maps all Song fields to StoredSong, sets `lastPlayedAt = Date()`
- [ ] `toDomain(from:)` — maps StoredSong back to Song domain model
- [ ] No SwiftData import in mapper

### RecentlyPlayedStore (Infra Protocol)
- [ ] `protocol RecentlyPlayedStore: Sendable` (internal to TuneCache)
- [ ] `func insert(_ song: Song) async throws`
- [ ] `func retrieveAll() async throws -> [StoredSong]`

### SwiftDataRecentlyPlayedStore
- [ ] `@ModelActor final actor SwiftDataRecentlyPlayedStore: RecentlyPlayedStore`
- [ ] `insert`: upsert — update `lastPlayedAt` if id exists, insert new `StoredSong` otherwise
- [ ] Fetches or creates a single `StoredPlayHistory` (singleton container); `modelContext.insert(history)` unconditionally when new
- [ ] `retrieveAll`: returns songs sorted by `lastPlayedAt` descending
- [ ] `modelContext.save()` after mutations; `modelContext.rollback()` + rethrow on error
- [ ] `import SwiftData` only in this file (+ the two `@Model` files)

### LocalRecentlyPlayedRepository
- [ ] `final class LocalRecentlyPlayedRepository: RecentlyPlayedRepository`
- [ ] `init(store: any RecentlyPlayedStore)`
- [ ] `save` delegates to `store.insert`
- [ ] `loadRecent(limit:)` calls `store.retrieveAll()`, maps with `StoredSongMapper.toDomain`, returns first `limit`
- [ ] No SwiftData import

### Composition Root
- [ ] `TuneFlowApp.init()` creates `ModelContainer(for: StoredSong.self, StoredPlayHistory.self, ...)`
- [ ] Creates `SwiftDataRecentlyPlayedStore(modelContainer:)` and `LocalRecentlyPlayedRepository(store:)`
- [ ] `private let recentlyPlayedRepository: any RecentlyPlayedRepository`
- [ ] `.modelContainer()` NOT called on the view hierarchy
- [ ] `RootView` receives `recentlyPlayedRepository`

### PlayerViewModel Integration
- [ ] `init` gains `recentlyPlayedRepository: any RecentlyPlayedRepository`
- [ ] `onAppear()` fires `Task { try? await recentlyPlayedRepository.save(song) }` (fire-and-forget; errors swallowed)

### PlayerComposer Integration
- [ ] `compose(...)` gains `recentlyPlayedRepository` parameter, passes to `PlayerViewModel`

### RootView Integration
- [ ] Gains `recentlyPlayedRepository` parameter, passes to both composers

### SongsViewModel Integration
- [ ] `init` gains `recentlyPlayedRepository: any RecentlyPlayedRepository`
- [ ] `private(set) var recentSongs: [Song] = []`
- [ ] `var hasRecentSongs: Bool { !recentSongs.isEmpty }`
- [ ] `func loadRecentlyPlayed() async` — calls `loadRecent(limit: 10)`, silently sets `[]` on error

### SongsComposer Integration
- [ ] `compose(...)` gains `recentlyPlayedRepository` parameter, passes to `SongsViewModel`

### SongsView Integration
- [ ] `.onAppear` triggers `Task { await viewModel.loadRecentlyPlayed() }`
- [ ] When `hasRecentSongs`, renders `Section("Recently Played")` with `SongRowView` rows
- [ ] Tapping a recently played song calls `viewModel.selectSong(_:)`

### Testing — SwiftDataRecentlyPlayedStore
- [ ] `insert_newSong_persistsItInStore`
- [ ] `insert_sameSongTwice_updatesLastPlayedAtWithoutDuplicate`
- [ ] `insert_differentSongs_storesAll`
- [ ] `retrieveAll_onEmptyStore_returnsEmptyArray`
- [ ] `retrieveAll_afterInserts_returnsSortedByLastPlayedAtDescending`

### Testing — LocalRecentlyPlayedRepository
- [ ] `save_delegatesToStoreInsert`
- [ ] `save_passesCorrectSong`
- [ ] `save_onStoreError_throwsError`
- [ ] `loadRecent_delegatesToStoreRetrieveAll`
- [ ] `loadRecent_mapsStoredSongsBackToDomainSongs`
- [ ] `loadRecent_respectsLimit`
- [ ] `loadRecent_onStoreError_throwsError`

### Testing — StoredSongMapper
- [ ] `toStorage_mapsAllFieldsCorrectly`
- [ ] `toStorage_setsLastPlayedAtToApproximatelyNow`
- [ ] `toDomain_mapsAllFieldsCorrectly`

### Testing — PlayerViewModel (additions)
- [ ] `onAppear_callsSaveOnRecentlyPlayedRepository`
- [ ] `onAppear_saveFailure_doesNotCrashAndPlaybackContinues`

### Testing — SongsViewModel (additions)
- [ ] `loadRecentlyPlayed_onSuccess_populatesRecentSongs`
- [ ] `loadRecentlyPlayed_onFailure_setsRecentSongsToEmpty`
- [ ] `hasRecentSongs_returnsFalseWhenEmpty`
- [ ] `hasRecentSongs_returnsTrueAfterLoad`

---

## Tasks

### Task 1: Save Spec Documentation
Create `agent-os/specs/2026-04-13-1500-persistence-layer/` with plan.md, shape.md, standards.md, references.md.  
**Stories:** all | **ACs:** all (source of truth)

---

### Task 2: `RecentlyPlayedRepository` Protocol in TuneDomain
**New files:**
- `Packages/TuneDomain/Sources/TuneDomain/Repositories/RecentlyPlayedRepository.swift`

```swift
import Foundation

public protocol RecentlyPlayedRepository: Sendable {
    func save(_ song: Song) async throws
    func loadRecent(limit: Int) async throws -> [Song]
}
```

**Stories:** S1–S5 | **ACs:** Protocol Layer (all)

---

### Task 3: TuneCache Models + Mapper + Tests
**New files:**
- `TuneFlow/TuneCache/Models/StoredSong.swift`
- `TuneFlow/TuneCache/Models/StoredPlayHistory.swift`
- `TuneFlow/TuneCache/Mappers/StoredSongMapper.swift`
- `TuneFlowTests/TuneCache/StoredSongMapperTests.swift`

Key notes:
- `StoredSong` fields: `id: Int`, `title`, `artist`, `albumName`, `url`, `lastPlayedAt`, `artworkUrl?`, `cache: StoredPlayHistory?`
- Mapper: direct 1:1 mapping of Int ids, no conversion needed
- Mapper has NO `import SwiftData`

**Stories:** S1, S2, S3 | **ACs:** StoredSong Model, StoredPlayHistory Model, StoredSongMapper, Testing — StoredSongMapper

---

### Task 4: `RecentlyPlayedStore` + `SwiftDataRecentlyPlayedStore` + Tests
**New files:**
- `TuneFlow/TuneCache/Repositories/RecentlyPlayedStore.swift`
- `TuneFlow/TuneCache/Store/SwiftDataRecentlyPlayedStore.swift`
- `TuneFlowTests/TuneCache/SwiftDataRecentlyPlayedStoreTests.swift`

Key notes:
- Upsert: fetch one `StoredPlayHistory`; `modelContext.insert(history)` unconditionally when creating new (never check `history.id == nil`)
- `retrieveAll` sorts by `lastPlayedAt` descending in memory
- Tests use `ModelConfiguration(isStoredInMemoryOnly: true)`, register both `StoredSong.self` and `StoredPlayHistory.self`

**Stories:** S1, S2, S3 | **ACs:** RecentlyPlayedStore, SwiftDataRecentlyPlayedStore, Testing — SwiftDataRecentlyPlayedStore

---

### Task 5: `LocalRecentlyPlayedRepository` + `RecentlyPlayedStoreSpy` + Tests
**New files:**
- `TuneFlow/TuneCache/Repositories/LocalRecentlyPlayedRepository.swift`
- `TuneFlowTests/Helpers/RecentlyPlayedStoreSpy.swift`
- `TuneFlowTests/TuneCache/LocalRecentlyPlayedRepositoryTests.swift`

**Stories:** S1–S5 | **ACs:** LocalRecentlyPlayedRepository, Testing — LocalRecentlyPlayedRepository

---

### Task 6: Wire Composition Root
**Modified files:**
- `TuneFlow/TuneApp/TuneFlowApp.swift` — create `ModelContainer`, `SwiftDataRecentlyPlayedStore`, `LocalRecentlyPlayedRepository`; pass to `RootView`; NO `.modelContainer()` on view hierarchy
- `TuneFlow/TuneApp/Composers/RootView.swift` — add `recentlyPlayedRepository` param, thread to both composers
- `TuneFlow/TuneApp/Composers/PlayerComposer.swift` — add param, pass to `PlayerViewModel`
- `TuneFlow/TuneApp/Composers/SongsComposer.swift` — add param, pass to `SongsViewModel`

Note: `try!` acceptable in composition root `init` for `ModelContainer` — wrong schema is a programmer error, not a runtime condition.

**Stories:** S1, S4 | **ACs:** Composition Root, PlayerComposer Integration, RootView Integration, SongsComposer Integration

---

### Task 7: `PlayerViewModel` Integration + Tests
**Modified files:**
- `TuneFlow/TuneUI/Player/PlayerViewModel.swift` — add `recentlyPlayedRepository` param; `onAppear` fires `Task { try? await recentlyPlayedRepository.save(song) }`
- `TuneFlowTests/Player/PlayerViewModelTests.swift` — update `makeSUT`, add 2 new tests

**New files:**
- `TuneFlowTests/Helpers/RecentlyPlayedRepositorySpy.swift`

Note: use `await Task.yield()` in tests to let fire-and-forget Task execute on main actor before assertion.

**Stories:** S1 | **ACs:** PlayerViewModel Integration, Testing — PlayerViewModel additions

---

### Task 8: `SongsViewModel` + `SongsView` Integration + Tests
**Modified files:**
- `TuneFlow/TuneUI/Songs/SongsViewModel.swift` — add `recentlyPlayedRepository`, `recentSongs`, `hasRecentSongs`, `loadRecentlyPlayed()`
- `TuneFlow/TuneUI/Songs/SongsView.swift` — `.onAppear` triggers load; `Section("Recently Played")` when `hasRecentSongs`
- `TuneFlowTests/Songs/SongsViewModelTests.swift` — update `makeSUT`, add 4 new tests

**Stories:** S2, S4, S5 | **ACs:** SongsViewModel Integration, SongsView Integration, Testing — SongsViewModel additions

---

### Task 9: Validate All ACs
Walk through every AC. Verify `import SwiftData` in exactly 3 files. Trace full dependency chain from `TuneFlowApp` → `RootView` → both composers → both ViewModels. Run `swift test` inside `Packages/TuneDomain`. Tell user to run manually:
```
xcodebuild test -scheme TuneFlow -destination 'platform=iOS Simulator,name=iPhone 16'
```
**ACs:** All
