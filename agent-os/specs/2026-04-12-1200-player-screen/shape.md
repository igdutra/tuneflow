# Track 5 — Player Screen — Shaping Notes

## Scope

Full Player screen: streams iTunes 30s preview audio via AVPlayer, shows album artwork, song info, live progress bar + timestamps, transport controls (prev / play-pause / next), repeat toggle, and shuffle toggle. Includes forward/backward queue navigation and More Options integration.

## Decisions

### iOS 26 Observable AVFoundation (NEW — replaces KVO/Combine for state)

Starting iOS 26, AVPlayer/AVPlayerItem conform to `Observable`. This changes the architecture significantly:

- `AVPlayer.isObservationEnabled = true` must be set **once** in `TuneFlowApp` before any player is created — it is a global flag
- After opt-in, SwiftUI views observe `player.timeControlStatus`, `player.currentItem?.status`, `player.rate`, etc. **directly** — no KVO `.publisher(for:)`, no Combine, no `@Published` wrappers
- `isPlaying` in the view is just a computed var: `player?.timeControlStatus == .playing` — SwiftUI re-renders automatically when it changes
- Play button is disabled via: `player?.currentItem?.status != .readyToPlay`
- `addPeriodicTimeObserver` is **still required** for continuous time tracking (`currentTime`, `progress`) — the Observation framework only covers discrete state properties, not a continuous stream of time values

### AVPlayer stored in ViewModel, exposed to View

Because `AVPlayer` is now `@Observable`, the ViewModel holds the `AVAudioPlayerService` (which owns the `AVPlayer`) and exposes it. The view reads `viewModel.audioService.player?.timeControlStatus` directly — no mirrored `isPlaying` bool needed. This eliminates a whole class of state-sync bugs.

### No Combine in AVAudioPlayerService

With iOS 26 as the minimum target, `AVAudioPlayerService` uses:
- `addPeriodicTimeObserver` for time/progress (still the only way)
- `NotificationCenter` for `AVPlayerItemDidPlayToEndTime` (still needed — not covered by Observation)
- **No** `Combine` publishers, no `.sink`, no `cancellables` set

### AVAudioPlayerService is infrastructure in TuneUI, not TuneDomain

The `AudioPlayerService` protocol lives in `TuneDomain` (testable seam). The concrete `AVAudioPlayerService` lives in `TuneUI/Player/` — it imports AVFoundation; TuneDomain does not.

### Player lifecycle: onAppear / onDisappear (not .task)

Unlike data-loading screens that use `.task`, the player must stop when the view disappears. `.onAppear` → play, `.onDisappear` → stop.

### Repeat and Shuffle are real features

- **Repeat**: tracked as `isRepeatOn: Bool` on the ViewModel. When `AVPlayerItemDidPlayToEndTime` fires and repeat is on, the service seeks to zero and resumes instead of stopping.
- **Shuffle**: tracked as `isShuffleOn: Bool` on the ViewModel. `didTapForward()` picks a random queue index (≠ current) when shuffle is on; sequential otherwise.
- Both use the existing router pop+push navigation pattern — no `AVQueuePlayer` needed.

### AppRoute.player carries queue context

`AppRoute.player` must be updated to carry `queue: [Song]` and `currentIndex: Int` so the ViewModel knows where it sits in the list for prev/next/shuffle navigation.

### Backward skip threshold: 3 seconds

`currentTime > 3` → seek to zero (restart). Otherwise → navigate to previous song or restart if at start. Mirrors Apple Music / Spotify UX.

### Artwork URL: 100×100 → 600×600

iTunes returns 100×100 artwork. The ViewModel replaces the size substring in the URL string to get 600×600 for the full-screen player. Done in ViewModel, not the service.

## Context

- **Visuals:** `visuals/player.png` — dark screen, centered album art (280pt), bold track title, dimmed artist, progress bar with thumb, glass play button, prev/next controls, repeat icon (top-right of song info row)
- **References:** `AlbumViewModel.swift`, `AlbumComposer.swift` — same @Observable MVVM composer pattern
- **Product alignment:** Track 5 in the sequence; `.player(Song)` AppRoute case exists but needs queue/index added; `RootView` has a `Text` placeholder ready to replace

## Standards Applied

- **swift/audio-player** — AudioPlayerService protocol, AVAudioPlayerService rules, PlayerViewModel shape, spy pattern; updated for iOS 26 Observable APIs
- **swift/swiftui** — @Observable + @MainActor ViewModel, @Bindable in view, method references, composer pattern
- **swift/module-composition** — TuneDomain owns protocol; TuneUI owns concrete + views + composers
- **swift/testing** — @MainActor struct suite, makeSUT() typed tuple, spy pattern, #expect/#require
