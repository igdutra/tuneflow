# Track 6 — More Options Bottom Sheet — Plan

> Once a task is successfully completed, commit. One commit per task. Single line: task title + key files touched.

## Overview

Implement the More Options bottom sheet that appears when the user taps "..." on a song row. Navigation plumbing is already wired (`AppSheet.moreOptions(Song)`, `AppRouter.present()`, `RootView` sheet binding) — only the view and view model are missing. The placeholder `Text("More options — ...")` in `RootView` is replaced with the real implementation.

**Standards applied:** swift/swiftui, swift/testing

---

## Stories

### S1: Sheet appears with song context

Given the user taps "..." on a song row
When the bottom sheet slides up
Then it displays the song's title and artist name as a centered header

### S2: Sheet is visually spec-compliant

Given the bottom sheet is presented
When the user sees it
Then it has a #2C2C2E background, a centered drag handle, song title in 17pt Semibold #FFFFFF centered, and artist name in 13pt Regular #737373 centered

### S3: View album action row is present

Given the bottom sheet is visible
When the user looks at the action list
Then a single row with a leading music-note SF Symbol and "View album" label is visible

### S4: View album tap is a no-op (Track 7 stub)

Given the bottom sheet is visible
When the user taps "View album"
Then no crash occurs and no navigation happens (album route does not exist yet)

---

## Acceptance Criteria

### Layout & Visual
- [ ] Sheet background is `#2C2C2E`
- [ ] Only the top two corners have 12pt radius; bottom corners are square (`.presentationCornerRadius(12)`)
- [ ] Drag handle is 32×4pt, color `#3A3A3C`, horizontally centered at the top of the sheet
- [ ] Song title: 17pt Semibold `#FFFFFF`, horizontally centered
- [ ] Artist name: 13pt Regular `#737373`, horizontally centered, below the title
- [ ] Single action row: leading SF Symbol `music.note` at ~20pt `#FFFFFF`; label "View album" 17pt Regular `#FFFFFF`
- [ ] Sheet sizes to fit its content (`.presentationSizing(.fitted)`) — no excess empty space below the action row
- [ ] System drag indicator is hidden (`.presentationDragIndicator(.hidden)`) — custom handle used instead

### Behavior
- [ ] Song passed to `AppSheet.moreOptions(song)` drives the header (title + artist from that song)
- [ ] Tapping "View album" calls `viewModel.viewAlbum()` — currently a no-op (no crash, no navigation)
- [ ] `Button` (not `onTapGesture`) is used for the action row

### Architecture
- [ ] `MoreOptionsViewModel` is `@MainActor @Observable final class`
- [ ] View owns VM via `@State private var viewModel`, injected via `State(initialValue:)` in init
- [ ] No business logic in the view body
- [ ] `RootView` placeholder replaced: `MoreOptionsView(viewModel: MoreOptionsViewModel(song: song))`
- [ ] `TuneFlow.xcodeproj/project.pbxproj` is NOT modified

### Testing
- [ ] `MoreOptionsViewModelTests` uses `import Testing`, `@MainActor struct` suite, `makeSUT()` returning typed tuple
- [ ] Test: initial `songTitle` matches `song.trackName`
- [ ] Test: initial `artistName` matches `song.artistName`
- [ ] Test: `viewAlbum()` does not mutate any observable state

---

## Tasks

### Task 1: Save Spec Documentation ✅

### Task 2: MoreOptionsViewModel + Tests

Create `TuneFlow/TuneUI/MoreOptions/MoreOptionsViewModel.swift` and `TuneFlowTests/MoreOptions/MoreOptionsViewModelTests.swift`.

**Stories:** S1, S4
**ACs:** Architecture, Behavior "viewAlbum is no-op", Testing all

### Task 3: MoreOptionsView

Create `TuneFlow/TuneUI/MoreOptions/MoreOptionsView.swift`.

**Stories:** S1, S2, S3, S4
**ACs:** Layout & Visual all, Behavior all

### Task 4: Wire into RootView

Modify `TuneFlow/TuneUI/Navigation/RootView.swift`.

**Stories:** S1, S2, S3, S4
**ACs:** Architecture "RootView placeholder replaced"

### Task 5: Validate All ACs

Walk through every acceptance criterion and verify it has been implemented and tested. Flag any gaps.

**ACs:** All
