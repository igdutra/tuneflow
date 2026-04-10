# SwiftUI Standard

## Non-Negotiable Defaults

- `@Observable` for all new view models — mandatory, no exceptions
- `@MainActor` on all view models — they drive UI state
- `Swift 6` — all new code
- `NavigationStack` not `NavigationView`
- `Button` not `onTapGesture` for interactive elements

## Property Wrappers

| Situation | Wrapper |
|---|---|
| View-owned value state | `@State private var` |
| View-owned `@Observable` object | `@State private var viewModel = VM(...)` |
| Injected `@Observable` needing bindings | `@Bindable var viewModel: VM` |
| Read-only passed value | `let` |
| Read-only value needing `.onChange` | `var` |

Never use `@ObservedObject`, `@StateObject`, `@EnvironmentObject` in new iOS 17+ code.

If an `@Observable` type contains `@AppStorage`, `@SceneStorage`, or `@Query`, mark those with `@ObservationIgnored`.

## Why @Observable Changes Everything About State Design

`@Observable` uses **property-level granular tracking** — SwiftUI records which exact properties a view reads during `body` evaluation and only invalidates that view when those specific properties change. This is fundamentally different from `ObservableObject`, which broadcast a single `objectWillChange` signal whenever *any* `@Published` property mutated, causing every subscribing view to re-evaluate.

Implications for view model design:
- A view reading `viewModel.songs` will NOT re-render when `viewModel.searchText` changes
- Computed properties that depend on stored properties are automatically tracked — if `viewData` reads `songs`, SwiftUI tracks `songs` through it
- There is NO need to split state into separate observable objects for performance
- Use `@ObservationIgnored` on internal bookkeeping properties the UI never reads (timers, cancellables, pagination cursors)

## ViewState Pattern

Single source of truth for async screen state:

```swift
public enum ViewState: Sendable {
    case idle
    case loading
    case loaded
    case error(Error)
}

public extension ViewState {
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var error: Error? {
        if case .error(let error) = self { return error }
        return nil
    }
}
```

- No contradictory booleans (`isLoading`, `hasError`, `hasLoaded`)
- The view model owns this state machine
- **`ViewState` is not generic** — it does not carry data. Content lives in dedicated stored properties on the view model. This avoids duplicating data inside the enum and inside stored properties simultaneously
- The view renders content from stored/computed properties; `state` drives overlays only

## Screen Architecture

1. Main view owns the view model with `@State`
2. View model is `@MainActor @Observable final class`
3. View model owns `ViewState` (non-generic) as the state machine
4. View model owns stored properties for content (`songs`, `recentSongs`, etc.)
5. View model exposes **computed properties** for display-formatted data — derived from stored content, automatically tracked by `@Observable`
6. View renders content from computed properties; applies state-driven overlays on the root
7. User actions call view model intent methods — pass method references, not closures
8. Use cases hold business logic — never in the view body

## View Model Shape

The view model owns two complementary layers:
- `state` — drives the overlay (idle/loading/loaded/error)
- Stored content + computed display properties — the actual data

**Computed properties replace the old `viewData` stored property.** Because `@Observable` tracks property access through computed properties automatically, making display values computed eliminates the synchronization risk of maintaining parallel stored state. SwiftUI invalidates exactly the views that depend on the underlying stored properties.

```swift
@MainActor
@Observable
final class SongsViewModel {
    private let searchSongsUseCase: SearchSongsUseCase
    private let loadRecentUseCase: LoadRecentSongsUseCase

    private(set) var state: ViewState = .idle
    private(set) var songs: [Song] = []
    private(set) var recentSongs: [Song] = []
    var searchText = ""

    // Computed display properties — automatically tracked by @Observable
    var hasResults: Bool { !songs.isEmpty }
    var showRecentSection: Bool { songs.isEmpty && !recentSongs.isEmpty }

    @ObservationIgnored private var currentOffset = 0

    init(
        searchSongsUseCase: SearchSongsUseCase,
        recentSongsUseCase: LoadRecentSongsUseCase
    ) {
        self.searchSongsUseCase = searchSongsUseCase
        self.loadRecentUseCase = recentSongsUseCase
    }

    func load() async {
        state = .loading
        do {
            recentSongs = try await loadRecentUseCase.execute(limit: 10)
            state = .loaded
        } catch {
            state = .error(error)
        }
    }

    func search() async {
        state = .loading
        currentOffset = 0
        do {
            songs = try await searchSongsUseCase.execute(
                query: searchText, limit: 20, offset: 0
            )
            state = .loaded
        } catch {
            state = .error(error)
        }
    }

    func songTapped(_ song: Song) {
        // emit event, trigger navigation
    }
}
```

**When to use a ViewData struct instead of computed properties:** Only when the formatting is expensive (e.g., date formatting, attributed string building, image composition) AND the inputs don't change often. In that case, build the struct once on success and store it. For simple derived booleans and filtered arrays, prefer computed properties.

## Main View Ownership

The main screen owns its observable with `@State`, injected via init:

```swift
struct SongsMainView: View {
    @State private var viewModel: SongsViewModel

    init(viewModel: SongsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        SongsContentView(
            songs: viewModel.songs,
            recentSongs: viewModel.recentSongs,
            showRecentSection: viewModel.showRecentSection,
            onSongTap: viewModel.songTapped
        )
        .searchable(text: $viewModel.searchText)
        .onSubmit(of: .search) { Task { await viewModel.search() } }
        .stateOverlay(
            state: viewModel.state,
            errorAction: .init(title: "Retry") {
                Task { await viewModel.load() }
            }
        )
        .task { await viewModel.load() }
    }
}
```

Why `_viewModel = State(initialValue: viewModel)`:
- the view receives a pre-built view model from the composer
- `@State` keeps it alive across redraws
- avoids recreating the view model on every render

Pass method references (`viewModel.songTapped`) not inline closures to child views. It narrows the dependency and avoids accidental captures.

## State Overlay Pattern

Apply overlays — do not replace the root content with `if`/`switch`:

```swift
extension View {
    func stateOverlay(
        state: ViewState,
        errorTitle: String? = nil,
        errorMessage: String? = nil,
        errorAction: ErrorView.Action? = nil
    ) -> some View {
        self
            .opacity(state.isLoading || state.error != nil ? 0 : 1)
            .disabled(state.isLoading || state.error != nil)
            .overlay {
                if state.isLoading {
                    ProgressView()
                } else if state.error != nil {
                    ErrorView(
                        title: errorTitle,
                        message: errorMessage,
                        action: errorAction
                    )
                }
            }
    }
}
```

Why overlays over `if`/`switch` on the root:
- preserves view identity across state transitions
- avoids unnecessary content recreation
- preserves internal view state (scroll position, etc.)
- aligns with Demystify SwiftUI performance guidance

## Empty State Pattern

Use the same overlay principle for empty search results:

```swift
List {
    ForEach(songs) { song in
        SongRow(song: song)
    }
}
.overlay {
    if songs.isEmpty, !searchText.isEmpty {
        ContentUnavailableView.search(text: searchText)
    }
}
```

The underlying `List` stays stable; the empty state appears as an overlay.

## View Composition

- Extract complex sections into subviews — not large computed `var` properties
- Prefer modifiers over conditional insertion for same-view states
- Use `overlay`/`background` for decoration; `ZStack` only for true peer layers
- Keep `Button` action closures small — push logic to the view model
- Pass only the values a child view needs — not the full view model
- Subview decomposition also improves `@Observable` granularity: each subview tracks only the properties it reads

Avoid:
- large monolithic `body` implementations
- business logic inside `Button` closures
- view extensions that branch view identity with `if`

## Layout

- Prefer relative layout over hard-coded constants
- `.frame(maxWidth: .infinity, alignment:)` over `Spacer` wrappers for full-width views
- Avoid excessive `GeometryReader`
- Flatten deep hierarchies
- Do not assume full-screen presentation, fixed device size, or fixed Dynamic Type size

## Accessibility

- `Button` not `onTapGesture` — gives VoiceOver traits, keyboard focus, and semantic intent automatically
- Use system text styles or Dynamic Type-aware fonts
- Hide decorative images with `.accessibilityHidden(true)`
- Group related elements with `accessibilityElement(children:)`
- Add clear labels when the default accessibility label is weak

## Performance

- `@Observable` provides property-level granularity — only views reading the changed property re-evaluate
- Use `@ObservationIgnored` on non-UI internal state (pagination offsets, cancellables, caches)
- Use stable identity in `ForEach` — never `.indices` for dynamic content
- Narrow the values passed into child views — this also limits observation scope
- Prefer lazy containers (`LazyVStack`, `List`) for larger collections
- Avoid redundant state assignments when the value did not change
- Use `Self._logChanges()` in debug builds when view invalidation is unclear

## Modern API Defaults

| Use | Instead of |
|---|---|
| `NavigationStack` | `NavigationView` |
| `.foregroundStyle(...)` | `.foregroundColor(...)` |
| `.animation(_:value:)` | deprecated `.animation(...)` |
| `.confirmationDialog(...)` | `actionSheet` |
| `NavigationLink(value:)` + `.navigationDestination(for:)` | `NavigationLink` with destination closure |
| `.alert(_:isPresented:actions:message:)` | deprecated alert patterns |

Gate version-specific APIs with `#available`. Only adopt Liquid Glass when explicitly requested.

## Testing

Test the view model first — no view rendering required.

Topics to cover per screen:
- initial state is `.idle` (or the declared starting state)
- `load()` transitions to `.loading` then to `.loaded` or `.error`
- stored content properties are populated correctly after success
- computed display properties return correct values given the stored content
- failure transitions to `.error` with the correct error type
- intent methods (taps, searches) trigger the correct use case calls
- events are emitted at the correct time

```swift
@Test func load_onSuccess_populatesSongs() async {
    let (sut, spy) = makeSUT()
    spy.stub(result: [Song.fixture])

    await sut.load()

    #expect(sut.state == .loaded)
    #expect(sut.recentSongs.count == 1)
    #expect(sut.showRecentSection == true)
}

@Test func load_onFailure_transitionsToError() async {
    let (sut, spy) = makeSUT()
    spy.stub(error: SongError.notFound)

    await sut.load()

    #expect(sut.state.error is SongError)
    #expect(sut.songs.isEmpty)
}
```

ViewInspector can be added later for overlay visibility, empty state, and accessibility label assertions. Not the default today.
