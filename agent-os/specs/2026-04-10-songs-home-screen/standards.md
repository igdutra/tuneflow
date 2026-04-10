# Standards for Track 4 — Songs Home Screen

The following standards apply to this work.

---

## swift/module-composition

**Why it applies:** Defines where TuneUI lives, what it can import, and how the composer pattern works. Critical for correct dependency direction.

See full content: `agent-os/standards/swift/module-composition.md`

Key rules for this feature:
- `TuneUI` must not import `TuneAPI` or `SwiftData`
- `TuneUI` imports only `TuneDomain` protocols
- `TuneFlowApp` is the composition root — only place that imports all modules
- Feature Composers live in `TuneUI/Composers/`, receive `TuneDomain` protocols only
- ViewModels take domain protocols in init; composers create them

---

## swift/swiftui

**Why it applies:** Governs ViewModel architecture, ViewState pattern, property wrappers, and view composition rules.

See full content: `agent-os/standards/swift/swiftui.md`

Key rules for this feature:
- `@MainActor @Observable final class` for all ViewModels
- `ViewState` enum (non-generic): drives overlays only, content in stored properties
- Main view owns ViewModel with `@State`, injected via `State(initialValue:)`
- Pass method references to child views, not closures
- `@ObservationIgnored` on pagination internals (offset, hasReachedEnd)
- `NavigationStack`, not `NavigationView`
- Use `List` for production data (per DESIGN.md guidance)
- `.searchable` + `.onSubmit(of: .search)` for search

---

## swift/testing

**Why it applies:** All ViewModel tests use Swift Testing. The SongsViewModel is @MainActor, so the suite gets @MainActor.

See full content: `agent-os/standards/swift/testing.md`

Key rules for this feature:
- `struct` suite with `@MainActor` (because SongsViewModel requires main-thread isolation)
- `makeSUT()` returning typed tuple `(sut: SongsViewModel, spy: SongRepositorySpy)`
- `SongRepositorySpy` is a `final class` Spy (records calls + supports stubbing)
- Test naming: `subject_condition_expectedOutcome`
- `#expect` default; `#require` for prerequisites
- No `Task.sleep` for async synchronization
- `source: SourceLocation = #_sourceLocation` in `makeSUT()` even if unused today
