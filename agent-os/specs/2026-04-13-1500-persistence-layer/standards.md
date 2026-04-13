# Standards for Track 3 — Persistence Layer

The following standards apply to this work.

---

## swift/module-composition

- `TuneCache` lives in app target as `TuneFlow/TuneCache/` folder
- `TuneDomain` owns all protocols — `RecentlyPlayedRepository` goes there
- Composition root (`TuneFlowApp`) is the only place that imports all modules and wires them together
- Composers accept `TuneDomain` protocols only — never concrete types from `TuneCache`
- `TuneUI` must not know about SwiftData models
- `TuneCache` must not depend on screen types

---

## swift/swiftdata-persistence

- `import SwiftData` confined to ONE file (plus the `@Model` definition files)
- `@Model final class` for stored models; `@Attribute(.unique)` for identity fields
- Use same ID types as domain models — `StoredSong.id: Int` matches `Song.id: Int` (no conversion in mapper)
- Cascade relationship: child (`StoredSong`) must have optional parent reference (`cache: StoredPlayHistory?`)
- `@ModelActor` for the store — provides `modelContext` automatically
- Always `modelContext.save()` after mutations; `modelContext.rollback()` before rethrow on error
- Mapper is `enum` with static methods only — no SwiftData import
- Tests: `ModelConfiguration(isStoredInMemoryOnly: true)`, register all `@Model` types in `ModelContainer(for:)`

---

## swift/testing

- `import Testing` — no XCTest
- `struct` suites; `makeSUT()` returns typed tuple with all doubles
- Spies (`___Spy`) for interaction verification; stubs for return values
- `#expect` default; `#require` for prerequisites and captured throws
- `@MainActor` only when SUT requires it (ViewModels yes, repositories/mappers no)
- No `Task.sleep` for synchronization (exception: SwiftData timestamp ordering tests — 10ms, documented)
