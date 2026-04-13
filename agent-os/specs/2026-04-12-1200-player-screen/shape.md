# Track 5 — Player Screen — Shaping Notes

## Scope

Full Player screen: streams iTunes 30s preview audio via AVPlayer, shows album artwork, song info, live progress bar + timestamps, and transport controls (prev / play-pause / next). Includes forward/backward queue navigation and More Options integration.

## Decisions

- `AVPlayer` (not `AVAudioPlayer`) — iTunes preview URLs are remote `.m4a` streams; AVAudioPlayer is local-only
- `AudioPlayerService` protocol lives in `TuneDomain` — the ViewModel depends only on the protocol, enabling spy-based testing without real audio
- `AVAudioPlayerService` concrete implementation lives in `TuneUI` — it is infrastructure, not domain
- `AVAudioPlayerService` is created inside `PlayerComposer`, not injected from the app root — player instances are per-navigation, not global singletons
- Progress bar is display-only (no scrubbing) matching mockup
- Backward-skip follows standard music player UX: >3s = restart, ≤3s = go to previous
- No audio interruption handling in scope (phone calls, alarms)
- No iOS 26 Observable AVPlayer APIs — KVO/Combine approach for iOS 17+ compatibility
- Repeat/shuffle button is a visual placeholder only

## Context

- **Visuals:** `visuals/player.png` — dark screen, centered album art (280pt), bold track title, dimmed artist, progress bar with thumb, glass play button, prev/next controls
- **References:** `AlbumViewModel.swift`, `AlbumComposer.swift` — same MVVM composer pattern to follow
- **Product alignment:** This is Track 5 in the implementation sequence; the `.player(Song)` AppRoute case already exists in `AppRoute.swift` and `RootView` has a placeholder `Text` ready to replace

## Standards Applied

- swift/audio-player — core architecture: AudioPlayerService protocol, AVAudioPlayerService rules, PlayerViewModel shape, spy pattern for tests
- swift/swiftui — @Observable + @MainActor ViewModel, ViewState pattern, @Bindable in view, method references not closures, composer pattern
- swift/module-composition — TuneDomain owns protocol, TuneUI owns concrete + views + composers, no cross-layer leakage
- swift/testing — @MainActor struct suite, makeSUT() returning typed tuple, spy vs stub, #expect/#require
