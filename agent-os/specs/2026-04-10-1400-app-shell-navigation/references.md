# References for Track 1 — App Shell & Navigation

## Similar Implementations

### SongsViewModel
- **Location:** `TuneFlow/TuneUI/Songs/SongsViewModel.swift`
- **Relevance:** The ViewModel pattern to follow — `@MainActor @Observable final class`, `@ObservationIgnored` for non-UI state, `private(set)` for public read / private write
- **Key patterns:** Existing `init(repository:)` becomes `init(repository:router:)`; `selectSong` follows the same pattern as `search()` and `loadMore()`

### SongsComposer
- **Location:** `TuneFlow/TuneUI/Composers/SongsComposer.swift`
- **Relevance:** Composition pattern — `@MainActor enum` with static `compose(...)` factory; updated to accept router

### SongsViewModelTests
- **Location:** `TuneFlowTests/Songs/SongsViewModelTests.swift`
- **Relevance:** Existing `makeSUT()` pattern with `SongRepositorySpy`; the navigation tests follow the same `typealias SUTBundle` + `makeSUT()` structure

### Song+Fixture
- **Location:** `TuneFlowTests/Helpers/Song+Fixture.swift`
- **Relevance:** `Song.fixture()` and `Song.fixtures(count:)` are used in tests; `AppRouterTests` and `SongsViewModelNavigationTests` reuse these
