# Standards for Track 6 — More Options Bottom Sheet

The following standards apply to this work.

---

## swift/swiftui

**Why it applies:** Governs ViewModel architecture, property wrappers, view composition, and sheet presentation patterns.

See full content: `agent-os/standards/swift/swiftui.md`

Key rules for this feature:
- `@MainActor @Observable final class` for MoreOptionsViewModel
- Main view owns ViewModel with `@State`, injected via `State(initialValue:)`
- `Button` not `onTapGesture` for the action row
- Computed properties (`songTitle`, `artistName`) for display — no stored copies
- No business logic in the view body; all intent through VM methods
- Sheet modifiers on the root view: `.presentationSizing(.fitted)`, `.presentationDragIndicator(.hidden)`, `.presentationCornerRadius(12)`, `.presentationBackground(...)`

---

## swift/testing

**Why it applies:** All VM tests use Swift Testing. `MoreOptionsViewModel` is `@MainActor`, so the suite requires `@MainActor`.

See full content: `agent-os/standards/swift/testing.md`

Key rules for this feature:
- `@MainActor struct` suite
- `makeSUT()` returning typed tuple `(sut: MoreOptionsViewModel, song: Song)`
- No spy needed — no async operations, no external dependencies at this stage
- `Song.fixture()` from `TuneFlowTests/Helpers/Song+Fixture.swift`
- Test naming: `subject_condition_expectedOutcome`
- `#expect` default assertion
- `source: SourceLocation = #_sourceLocation` in `makeSUT()` even if unused today
