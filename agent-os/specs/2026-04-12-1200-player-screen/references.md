# References for Track 5 — Player Screen

## Similar Implementations

### AlbumViewModel

- **Location:** `TuneFlow/TuneUI/Album/AlbumViewModel.swift`
- **Relevance:** Exact MVVM shape to follow — `@MainActor @Observable final class`, state machine with `ViewState`, computed display properties, dependency injection via init
- **Key patterns:** `private(set) var state: ViewState = .idle`, computed properties derived from stored content, `async func load()`

### AlbumComposer

- **Location:** `TuneFlow/TuneUI/Composers/AlbumComposer.swift`
- **Relevance:** The PlayerComposer must follow the same `@MainActor enum` composer pattern
- **Key patterns:** Accepts domain protocols, instantiates ViewModel, returns the View

### AlbumView

- **Location:** `TuneFlow/TuneUI/Album/AlbumView.swift`
- **Relevance:** Reference for view structure, `@Bindable` usage, toolbar setup with `.toolbarBackground(.hidden)` and `.toolbarColorScheme(.dark)`, `@State private var viewModel` initialized via `State(initialValue:)` in init

### RootView

- **Location:** `TuneFlow/TuneUI/Navigation/RootView.swift`
- **Relevance:** The `.player(let song)` case in `navigationDestination` is a `Text` placeholder (line 18) — Task 5 replaces this with `PlayerComposer.compose(...)`

### AppRoute

- **Location:** `TuneFlow/TuneUI/Navigation/AppRoute.swift`
- **Relevance:** `.player(Song)` case already exists — no changes needed

### AppRouter

- **Location:** `TuneFlow/TuneUI/Navigation/AppRouter.swift`
- **Relevance:** `push(_:)`, `pop()`, `present(_:)` — the router API the ViewModel calls for navigation

### Song+Fixture

- **Location:** `TuneFlowTests/Helpers/Song+Fixture.swift`
- **Relevance:** `Song.fixture(previewURL:)` already supports a preview URL — reuse directly in `PlayerViewModelTests`

### SongsViewModel

- **Location:** `TuneFlow/TuneUI/Songs/SongsViewModel.swift`
- **Relevance:** `songTapped(_:)` must be updated in Task 5 to push `.player(song)` with queue and index — check current implementation before modifying
