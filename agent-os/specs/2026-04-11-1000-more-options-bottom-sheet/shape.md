# Track 6 — More Options Bottom Sheet — Shaping Notes

## Scope

Build the bottom sheet that appears when the user taps "..." on a song row. The sheet shows the song's title and artist as a centered header, and a single "View album" action row. The album navigation (Track 7) is a no-op stub for now.

## Key Decisions

- **Navigation already wired** — `AppSheet.moreOptions(Song)`, `AppRouter.present()`, and the `RootView` `.sheet()` binding all exist. Only the view + view model need to be created.
- **No Composer needed** — The sheet is lightweight and stateless. The `RootView` switch is the appropriate composition point (mirrors how the player placeholder is wired). A dedicated `MoreOptionsComposer` would be an over-abstraction.
- **`viewAlbum()` is a documented no-op** — The method exists on the VM so Track 7 only needs to fill in the body, without touching the view.
- **No `router` dependency in this track** — Injecting `AppRouter` now without using it is dead code. Track 7 will add it.
- **Sheet height: `.presentationSizing(.fitted)`** — The app targets iOS 26. `.fitted` (available since iOS 18) sizes the sheet to exactly its content — no empty gap. `.medium` would occupy ~50% screen height, which is excessive for one action row. The mockup confirms a compact sheet.
- **Custom drag handle, not system indicator** — `.presentationDragIndicator(.hidden)` suppresses the system one; a manual `RoundedRectangle` (32×4pt, #3A3A3C) is rendered at the top of the `VStack`.
- **`computed properties` for display** — `songTitle` and `artistName` are computed from the injected `song`, consistent with the `@Observable` standard. No stored copy needed since `song` never mutates.

## Context

- **Visuals:** `mockups/action_sheet.png`
- **References:** `TuneFlow/TuneUI/Songs/SongsViewModel.swift`, `TuneFlow/TuneUI/Navigation/RootView.swift`
- **Product alignment:** Track 6 of Phase 1 MVP — bridges song list to album view

## Standards Applied

- `swift/swiftui` — @Observable ViewModel, State(initialValue:) ownership, Button not onTapGesture, no logic in view body
- `swift/testing` — @MainActor struct suite, makeSUT(), typed tuple, #expect, no XCTest
