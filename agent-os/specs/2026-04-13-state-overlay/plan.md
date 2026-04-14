# State Overlay Implementation Plan

## Context

`SongsView` and `AlbumView` both had TODO comments for loading and error overlays. The `ViewState` enum existed but used `.error` (no associated value) — the standard requires `.error(Error)` with an associated value so the error can be surfaced in the UI.

The standard (`agent-os/standards/swift/swiftui.md`) defines:
- `ViewState` with `.error(Error)` associated value
- A `stateOverlay` View extension using `ProgressView` for loading and `ErrorView` for error
- `ContentUnavailableView.search(text:)` for empty search results (overlay on List)

## Tasks

### Task 1 — Update `ViewState` to carry associated error
**File:** `TuneFlow/TuneUI/Shared/ViewState.swift`

- Changed `.error` → `.error(any Error & Sendable)`
- Replaced `hasError: Bool` with `error: (any Error)?` computed property

### Task 2 — Create `ErrorView`
**New file:** `TuneFlow/TuneUI/Shared/ErrorView.swift`

Minimal dark-themed SwiftUI view with optional title, message, and retry action button.

### Task 3 — Create `View+StateOverlay` extension
**New file:** `TuneFlow/TuneUI/Shared/View+StateOverlay.swift`

```swift
extension View {
    func stateOverlay(
        state: ViewState,
        errorTitle: String? = nil,
        errorMessage: String? = nil,
        errorAction: ErrorView.Action? = nil
    ) -> some View
}
```
- `.opacity(0)` + `.disabled(true)` when loading or error
- Overlay `ProgressView()` when loading
- Overlay `ErrorView(...)` when error

### Task 4 — Fix ViewModels to pass error into `ViewState`
**Files:** `SongsViewModel.swift`, `AlbumViewModel.swift`

- Changed `state = .error` → `state = .error(error)` in catch blocks
- Removed `// TODO: save error` comments

### Task 5 — Apply `stateOverlay` to `SongsView`
**File:** `TuneFlow/TuneUI/Songs/SongsView.swift`

- Added `.stateOverlay(state:errorAction:)` with retry calling `viewModel.search()`
- Added empty state overlay using `ContentUnavailableView.search(text:)` when loaded + no results
- Removed 3 TODO comments

### Task 6 — Apply `stateOverlay` to `AlbumView`
**File:** `TuneFlow/TuneUI/Album/AlbumView.swift`

- Added `.stateOverlay(state:errorAction:)` with retry calling `viewModel.load()`
- Removed 2 TODO comments

## New files added (must be added to Xcode manually)
- `TuneFlow/TuneUI/Shared/ErrorView.swift`
- `TuneFlow/TuneUI/Shared/View+StateOverlay.swift`

## Verification
- Build the app target in Xcode to confirm no compiler errors
- Search with network off → error overlay with "Retry" button appears
- Search with no results → `ContentUnavailableView` appears
- Normal search → `ProgressView` shows briefly, then results appear
- Open album → `ProgressView` shows briefly, then tracks appear
