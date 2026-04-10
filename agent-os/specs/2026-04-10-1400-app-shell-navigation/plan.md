# Track 1 — App Shell & Navigation Plan

> Once a task is successfully completed, commit. One commit per task. Single line: task title + key files touched.

## Overview

Track 1 establishes the navigation backbone of the app: a splash screen, a centralized router, and a root navigation shell. Currently, `SongsView` owns its own `NavigationStack` (wrong — it should live in a root shell), `SongsViewModel` has no router dependency, and there's no splash screen. This track puts all of that in place without touching search/pagination logic.

**Standards applied:** Navigation Router Standard (navigation-router-standard.md), SwiftUI Standard, Testing Standard

---

## Stories

### S1: App shows splash on launch
Given the app is launched  
When it appears for the first time  
Then the splash image fills the screen

### S2: Splash disappears automatically
Given the splash screen is visible  
When 2 seconds have elapsed  
Then the splash fades out with an animation and the songs screen is revealed

### S3: Navigation to Player is router-driven
Given the user is on the Songs screen  
When they tap a song  
Then the app navigates to the Player screen without SongsView knowing about PlayerView

### S4: More Options sheet is router-driven
Given the user is on the Songs screen  
When they tap the More Options button  
Then the More Options bottom sheet appears without SongsView knowing about it directly

---

## Acceptance Criteria

### Splash
- [ ] `SplashView` displays `Image("splash")` scaled to fill, ignoring safe area
- [ ] Splash appears as an overlay on top of `RootView`, not as a navigation destination
- [ ] Splash dismisses after 2 seconds with `.easeInOut(duration: 0.5)` opacity animation
- [ ] The `splash` asset must be added to `Assets.xcassets` by the developer (asset named `splash`)

### Navigation Types
- [ ] `AppRoute: Hashable` enum exists with `.player(Song)` case (`.album` deferred to Track 7)
- [ ] `AppSheet: Identifiable` enum exists with `.moreOptions(Song)` case
- [ ] `Song` conforms to `Hashable` (synthesized — all stored properties are already hashable)

### AppRouter
- [ ] `AppRouter` is `@MainActor @Observable final class`
- [ ] Owns `path: NavigationPath` and `sheet: AppSheet?`
- [ ] `push(_:)` appends a route to the path
- [ ] `pop()` removes the last route; does nothing on empty path (no crash)
- [ ] `popToRoot()` clears all routes
- [ ] `present(_:)` sets the sheet
- [ ] `dismissSheet()` clears the sheet

### RootView
- [ ] `RootView` owns the `AppRouter` via `@State private var router = AppRouter()`
- [ ] Wraps content in `NavigationStack(path: $router.path)`
- [ ] Registers `.navigationDestination(for: AppRoute.self)` — placeholder `Text` for `.player` (replaced in Track 5)
- [ ] Registers `.sheet(item: $router.sheet)` — placeholder `Text` for `.moreOptions` (replaced in Track 6)
- [ ] Passes router via `.environment(router)` to descendants
- [ ] `SongsView` no longer owns a `NavigationStack`

### SongsViewModel & Composer
- [ ] `SongsViewModel.init` accepts `router: AppRouter` alongside `repository`
- [ ] `SongsViewModel` has `func selectSong(_ song: Song)` that calls `router.push(.player(song))`
- [ ] `SongsComposer.compose(songRepository:router:)` wires both dependencies
- [ ] `TuneFlowApp` passes `RootView(songRepository:)` instead of `SongsComposer.compose(...)`
- [ ] Existing `SongsViewModelTests.makeSUT()` updated to pass a real `AppRouter()`

### Tests
- [ ] `AppRouterTests` covers: initial state, push (single & multiple), pop, pop on empty, popToRoot, present, dismissSheet
- [ ] `SongsViewModelNavigationTests` covers: selectSong pushes to router path
- [ ] All tests use `Swift Testing`, `makeSUT()`, no XCTest

---

## Tasks

### Task 1: Save Spec Documentation
Create `agent-os/specs/2026-04-10-1400-app-shell-navigation/` with plan.md, shape.md, standards.md, references.md, and visuals/.

### Task 2: Add `Hashable` to `Song` + Define Navigation Types

**Modify:** `Packages/TuneDomain/Sources/TuneDomain/Models/Song.swift`  
Add `Hashable` to the conformance list.

**Create:** `TuneFlow/TuneUI/Navigation/AppRoute.swift`  
**Create:** `TuneFlow/TuneUI/Navigation/AppSheet.swift`

**Stories:** S3, S4  
**ACs:** Song: Hashable, AppRoute exists, AppSheet exists

### Task 3: Implement AppRouter

**Create:** `TuneFlow/TuneUI/Navigation/AppRouter.swift`

**Stories:** S3, S4  
**ACs:** All AppRouter ACs

### Task 4: Update SongsViewModel, SongsComposer, and Existing Tests

**Modify:** `TuneFlow/TuneUI/Songs/SongsViewModel.swift` — router injection + selectSong  
**Modify:** `TuneFlow/TuneUI/Composers/SongsComposer.swift` — add router param  
**Modify:** `TuneFlowTests/Songs/SongsViewModelTests.swift` — update makeSUT()

**Stories:** S3, S4  
**ACs:** SongsViewModel.init accepts router, selectSong exists, SongsComposer updated, existing tests pass

### Task 5: Build SplashView + RootView + Update TuneFlowApp

**Create:** `TuneFlow/TuneUI/Shared/SplashView.swift`  
**Create:** `TuneFlow/TuneUI/Navigation/RootView.swift`  
**Modify:** `TuneFlow/TuneUI/Songs/SongsView.swift` — remove NavigationStack  
**Modify:** `TuneFlow/TuneFlowApp.swift` — use RootView

Developer action: drag `mockups/splash.png` into `Assets.xcassets`, name it `splash`.

**Stories:** S1, S2, S3, S4  
**ACs:** SplashView, RootView, SongsView (no NavigationStack), TuneFlowApp updated

### Task 6: Write Tests

**Create:** `TuneFlowTests/Navigation/AppRouterTests.swift`  
**Create:** `TuneFlowTests/Songs/SongsViewModelNavigationTests.swift`

**Stories:** S3, S4  
**ACs:** All test ACs

### Task 7: Validate All ACs

Walk through every AC above and verify it's implemented and tested. Flag any gaps.

**ACs:** All

---

## New Files (user must add to Xcode)
- `TuneFlow/TuneUI/Navigation/AppRoute.swift`
- `TuneFlow/TuneUI/Navigation/AppSheet.swift`
- `TuneFlow/TuneUI/Navigation/AppRouter.swift`
- `TuneFlow/TuneUI/Navigation/RootView.swift`
- `TuneFlow/TuneUI/Shared/SplashView.swift`
- `TuneFlowTests/Navigation/AppRouterTests.swift`
- `TuneFlowTests/Songs/SongsViewModelNavigationTests.swift`
