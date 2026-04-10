# Standards for Track 1 — App Shell & Navigation

The following standards apply to this work.

---

## Navigation Router Standard

See full standard: `navigation-router-standard.md` (project root)

Key points:
- Single `AppRouter` (`@MainActor @Observable final class`) owns `NavigationPath` and sheet state
- Routes are `Hashable` enums carrying domain models, not ViewModels
- `RootView` is the sole wiring point: `.navigationDestination` and `.sheet` live here only
- ViewModels receive `AppRouter` via initializer injection; Views never call the router directly
- Splash is a state-driven overlay in the App entry point, not a navigation destination
- Test Router directly (plain class, no SwiftUI needed); use real `AppRouter` in VM tests

---

## SwiftUI Standard

See full standard: `agent-os/standards/swift/swiftui.md`

Key points:
- `@Observable` mandatory for all ViewModels
- `@MainActor` on all ViewModels
- `NavigationStack` not `NavigationView`
- `Button` not `onTapGesture`
- State overlay pattern — preserve view identity across state transitions
- Main view owns VM with `@State`, injected via init

---

## Testing Standard

See full standard: `agent-os/standards/swift/testing.md`

Key points:
- `import Testing` only — no XCTest
- `struct` suites, `@Test` on every function
- `makeSUT()` returns typed tuple with SUT and all doubles
- `@MainActor` on suite when SUT is `@MainActor` (ViewModels, AppRouter)
- Spy for interaction verification, Stub for return value control
- `#expect` default, `#require` for prerequisites
