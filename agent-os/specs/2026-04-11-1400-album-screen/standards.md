# Standards for Track 7 — Album Screen

The following standards apply to this work.

---

## swift/module-composition

**Why it applies:** Album screen wired via `AlbumComposer`; TuneUI must not import TuneAPI; domain models (`Song`, `Album`) cross layer boundaries upward; lookup DTOs stay internal to TuneAPI.

See full content: `agent-os/standards/swift/module-composition.md`

Key rules for this feature:
- `AlbumComposer` lives in `TuneUI/Composers/` and accepts `TuneDomain` protocols only
- `RemoteAlbumDTO` and `RemoteLookupPage` are internal to `TuneAPI` — never exposed upward
- `Album` domain model defined in `TuneDomain`, used by `TuneUI`
- `lookupBaseURL` injected at composition root (`TuneFlowApp`) — not hardcoded in repository

---

## swift/swiftui

**Why it applies:** Governs ViewModel architecture, property wrappers, view composition, and navigation patterns.

See full content: `agent-os/standards/swift/swiftui.md`

Key rules for this feature:
- `@MainActor @Observable final class` for `AlbumViewModel`
- Main view owns VM with `@State`, injected via `State(initialValue:)`
- Computed properties (`title`, `artistName`, `artworkURL`, `tracks`) derived from stored `album: Album?`
- State overlays deferred — TODO comments only, not implemented this track
- `Button` not `onTapGesture`
- No business logic in view body

---

## swift/testing

**Why it applies:** All VM and mapper tests use Swift Testing.

See full content: `agent-os/standards/swift/testing.md`

Key rules for this feature:
- `@MainActor struct` suite for `AlbumViewModelTests` (VM is `@MainActor`)
- `makeSUT()` returning typed tuple with SUT and spy
- `SongRepositorySpy` extended with `fetchAlbum` stub support
- Mapper tests are plain `struct` suites — no `@MainActor`, pure functions
- `#expect` default assertion, `#require` for unwrapping
- Parameterized tests for non-200 status codes
