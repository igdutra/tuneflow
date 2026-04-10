# Track 1 — App Shell & Navigation: Shaping Notes

## Scope

Establish the full navigation backbone: splash screen (PNG overlay), `AppRouter`, `AppRoute`/`AppSheet` enums, `RootView` (navigation shell), and wire everything through `TuneFlowApp`. Refactor `SongsView` to remove its self-owned `NavigationStack`. Add `selectSong(_:)` to `SongsViewModel` as the first router-calling action.

## Decisions

- **Splash is an overlay, not a nav destination.** State-driven `@State var isSplashVisible = true` in `RootView`, dismissed via `.task` sleep + animation. Matches navigation-router-standard.md.
- **Splash uses `splash.png` as-is.** No custom rendering. `Image("splash").resizable().scaledToFill().ignoresSafeArea()`. Asset must be added to `Assets.xcassets` by the developer.
- **`.album` route deferred.** Only `.player(Song)` in `AppRoute` for Track 1. Track 7 adds `.album`.
- **`Song: Hashable` added.** Required for `AppRoute.player(Song)` to be `Hashable`. Synthesized — no custom implementation.
- **`selectSong` in Task 4, not Task 5.** Cleaner to have the VM method tested before wiring the UI tap in Track 5.
- **Placeholder destinations.** `Text("Player — ...")` and `Text("More options — ...")` in `RootView` until Tracks 5 & 6.
- **Real `AppRouter` in VM tests.** No spy/mock needed — the router is simple enough that asserting `path.count` is more meaningful than asserting method call counts.

## Context

- **Visuals:** `mockups/splash.png` (asset ready, needs adding to asset catalog)
- **References:** Existing `SongsView`/`SongsViewModel`/`SongsComposer` in `TuneFlow/TuneUI/Songs/` and `Composers/`
- **Product alignment:** Track 1 on the roadmap — foundation for all subsequent tracks

## Standards Applied

- navigation-router-standard.md — Router pattern, splash as overlay, file structure, testing approach
- swift/swiftui.md — @Observable, @MainActor, NavigationStack, state overlay pattern
- swift/testing.md — Swift Testing, makeSUT(), Spy/Stub, @MainActor on VM tests
