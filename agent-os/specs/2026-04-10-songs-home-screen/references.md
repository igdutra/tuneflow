# References for Track 4 — Songs Home Screen

## Similar Implementations

### HTTPClientSpy → SongRepositorySpy pattern

- **Location:** `Packages/TuneAPI/Tests/TuneAPITests/Helpers/HTTPClientSpy.swift`
- **Relevance:** The `SongRepositorySpy` in `TuneFlowTests/Helpers/` follows this exact pattern — final class, `@unchecked Sendable`, recorded calls, `stub(result:)` / `stub(error:)` methods.
- **Key patterns:** `private(set) var` for recorded state, `private var stubbedResult: Result<..., Error>`, `get()` call in the implementation method.

### Song+Fixture

- **Location:** `Packages/TuneAPI/Tests/TuneAPITests/Helpers/Song+Fixture.swift`
- **Relevance:** The app test target (`TuneFlowTests`) needs its own copy — it cannot import from TuneAPI's test target. Identical pattern, local scope.
- **Key patterns:** `static func fixture(...)` with defaulted parameters, all-optional overrides.

### RemoteSongRepository

- **Location:** `Packages/TuneAPI/Sources/TuneAPI/RemoteSongRepository.swift`
- **Relevance:** Shows how `SongRepository` protocol is implemented. The `search(query:limit:offset:)` signature is the contract the SongsViewModel calls.

### SwiftUI Standard — ViewModel shape

- **Location:** `agent-os/standards/swift/swiftui.md`
- **Relevance:** The standard provides the exact `SongsViewModel` skeleton with `@ObservationIgnored` pagination internals, `ViewState` pattern, and the `SongsMainView` ownership pattern.

### Module Composition Standard — Composer pattern

- **Location:** `agent-os/standards/swift/module-composition.md`
- **Relevance:** The `SongsComposer` example in the standard shows exactly how the composition root wires `SongRepository` → `SongsViewModel` → `SongsView`.
