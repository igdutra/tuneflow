# References for Track 6 — More Options Bottom Sheet

## Similar Implementations

### SongsViewModel — ViewModel shape reference

- **Location:** `TuneFlow/TuneUI/Songs/SongsViewModel.swift`
- **Relevance:** `MoreOptionsViewModel` follows the same shape: `@MainActor @Observable final class`, injected dependency in init, computed display properties.
- **Key patterns:** `private(set)` stored properties, computed booleans, intent methods.

### RootView — Wiring point

- **Location:** `TuneFlow/TuneUI/Navigation/RootView.swift`
- **Relevance:** The `.sheet(item:)` binding and switch over `AppSheet` is where `MoreOptionsView` gets wired in (replacing the `Text` placeholder).
- **Key patterns:** `case .moreOptions(let song):` → construct VM inline → pass to view.

### AppSheet — Enum definition

- **Location:** `TuneFlow/TuneUI/Navigation/AppSheet.swift`
- **Relevance:** `AppSheet.moreOptions(Song)` carries the `Song` into the sheet. No changes needed.

### Song+Fixture — Test data

- **Location:** `TuneFlowTests/Helpers/Song+Fixture.swift`
- **Relevance:** Used in `MoreOptionsViewModelTests` to construct a `Song` with controlled field values.
- **Key patterns:** `static func fixture(trackName:artistName:...)` with defaulted parameters.

### SongsViewModelTests — Test suite structure

- **Location:** `TuneFlowTests/Songs/SongsViewModelTests.swift`
- **Relevance:** `MoreOptionsViewModelTests` follows the same structure: `@MainActor struct`, `makeSUT()` in a `private extension`, typed tuple return.
