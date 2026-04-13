# Track 5 — Player Screen — Plan

> Once a task is successfully completed, commit. One commit per task. Single line: task title + key files touched.

## Overview

Implement the Player screen that opens when a song is tapped. The screen streams the song's iTunes 30-second preview URL using `AVPlayer`, displays large album artwork, track title, artist name, a live progress bar with timestamps, and transport controls (previous / play-pause / next). The ViewModel owns the full `AVPlayer` lifecycle via an `AudioPlayerService` protocol, keeping the view thin and the service fully testable without real audio hardware.

**Standards applied:** swift/audio-player, swift/module-composition, swift/swiftui, swift/testing

---

## Stories

### S1: Player opens and begins playing

Given the user taps a song anywhere in the app
When the Player screen appears
Then the song's preview starts playing automatically, the play button shows a pause icon, and the progress bar advances in real time

### S2: Play / Pause toggle

Given the Player screen is visible
When the user taps the play/pause button
Then playback pauses or resumes and the button icon toggles accordingly

### S3: Progress bar reflects playback position

Given the song is playing
When time advances
Then the progress bar fill and elapsed time label update continuously; the remaining time label counts down

### S4: Playback reaches the end

Given the 30-second preview is playing
When it reaches the end
Then playback stops, the progress bar is full, and the play button returns to the play icon (ready to restart)

### S5: Previous / Next navigation

Given the user arrived at the Player from a list of songs (queue)
When they tap the previous or next button
Then the app navigates to the previous or next song in the queue

### S6: Backward skip restarts current song when deep into playback

Given the user is more than 3 seconds into a song
When they tap the previous button
Then the song restarts from the beginning instead of navigating to the previous song

### S7: Player screen dismissed / navigated away

Given the user is on the Player screen
When they navigate back (system back or pop)
Then playback stops cleanly — no audio continues in the background

### S8: More Options from Player

Given the user is on the Player screen
When they tap the ellipsis (…) button
Then the More Options bottom sheet appears for the current song

### S9: Song with no preview URL

Given the user taps a song that has no preview URL
When the Player screen appears
Then the screen renders correctly (artwork, title, artist) with playback controls disabled or inert — no crash

---

## Acceptance Criteria

### Domain / Protocol
- [ ] `AudioPlayerService` protocol added to `TuneDomain/Services/` with: `play(url:)`, `pause()`, `resume()`, `stop()`, `seek(to:)`, `var isPlaying: Bool`, `var currentTime: TimeInterval`, `var duration: TimeInterval`, `var progress: Double`
- [ ] Protocol is `AnyObject & Sendable`
- [ ] No AVFoundation import in `TuneDomain`

### AVAudioPlayerService (concrete implementation)
- [ ] `AVAudioPlayerService` lives in `TuneUI/` (not TuneDomain — it is infrastructure)
- [ ] Configures `AVAudioSession` with `.playback` category before first play
- [ ] Creates `AVPlayer` from URL; does NOT download before playing
- [ ] Uses `addPeriodicTimeObserver` with 0.25s interval, `preferredTimescale: 600` for progress updates
- [ ] Guards `duration.isFinite && duration > 0` before updating progress
- [ ] Observes `AVPlayerItemDidPlayToEndTime` via `NotificationCenter` publisher to detect end of playback
- [ ] Removes time observer token before releasing player (in `stop()` AND `deinit` safety net)
- [ ] Cancels all Combine subscriptions in `stop()`
- [ ] `stop()` is idempotent — safe to call multiple times
- [ ] Artwork URL upgraded from 100×100 → 600×600 by replacing the size substring (in ViewModel, not service)

### PlayerViewModel
- [ ] `PlayerViewModel` is `@MainActor @Observable final class`
- [ ] Receives `Song`, `queue: [Song]`, `currentIndex: Int`, `audioPlayer: AudioPlayerService`, `router: AppRouter` via init
- [ ] Never imports `AVFoundation`
- [ ] Exposes read-only observable: `isPlaying`, `progress`, `currentTime`, `duration`
- [ ] Exposes computed: `currentTimeFormatted`, `durationFormatted` (format: `M:SS`)
- [ ] Exposes `artworkURL: URL?` — replaces `100x100` with `600x600` in the artwork URL string
- [ ] `onAppear()` — calls `audioPlayer.play(url:)` with `song.previewURL` (guard nil safely)
- [ ] `onDisappear()` — calls `audioPlayer.stop()`
- [ ] `didTapPlayPause()` — toggles `pause()` / `resume()` based on `isPlaying`
- [ ] `didTapBackward()` — seeks to zero if `currentTime > 3`; otherwise `router.pop()` then `router.push(.player(queue[currentIndex - 1]))` if `prevIndex >= 0`, else seeks to zero
- [ ] `didTapForward()` — `router.pop()` then `router.push(.player(queue[nextIndex]))` if `nextIndex < queue.count`
- [ ] `didTapMoreOptions()` — `router.present(.moreOptions(song))`
- [ ] `@ObservationIgnored` on `router`, `audioPlayer`, `queue`, `currentIndex` (non-UI internals)

### PlayerView
- [ ] `PlayerView` uses `@Bindable var viewModel: PlayerViewModel`
- [ ] Matches mockup: pure `#000000` background, centered 280pt square album artwork (cornerRadius 16pt), track title (32pt Bold #FFFFFF), artist (16pt Regular #FFFFFF @ 70%), repeat icon placeholder (trailing)
- [ ] Progress bar: track `#3A3A3C`, fill `#FFFFFF`, thumb `#FFFFFF` 12pt circle; elapsed label left, remaining label right (13pt #FFFFFF @ 60%)
- [ ] Transport controls: backward (28pt), play/pause (56pt circle with glass treatment), forward (28pt)
- [ ] Play button: `#3A3A3C` + `.ultraThinMaterial` blur overlay, 1pt `rgba(255,255,255,0.10)` border — matches DESIGN.md glass spec
- [ ] Nav bar: compact centered album title (17pt Semibold #FFFFFF), back button (circular 44pt #1C1C1E glass), ellipsis button right
- [ ] `.toolbarBackground(.hidden)`, `.toolbarColorScheme(.dark)`
- [ ] `Button` (not `onTapGesture`) for all interactive elements
- [ ] `.onAppear` → `viewModel.onAppear()`, `.onDisappear` → `viewModel.onDisappear()`
- [ ] No business logic in view body

### PlayerComposer
- [ ] `PlayerComposer` lives in `TuneUI/Composers/`
- [ ] Accepts `song: Song`, `queue: [Song]`, `currentIndex: Int`, `router: AppRouter`
- [ ] Creates `AVAudioPlayerService()` and `PlayerViewModel` internally, returns `PlayerView`
- [ ] `RootView` replaces the `Text("Player — ...")` placeholder with `PlayerComposer.compose(...)`

### Navigation wiring
- [ ] `RootView` passes `queue` and `currentIndex` when composing the Player — `SongsViewModel` must supply these
- [ ] `SongsViewModel.songTapped(_:)` pushes `.player(song)` with queue = current results and index = tapped index
- [ ] `AppRoute.player` already exists with associated `Song` — no change needed to the enum

### Testing — `TuneFlowTests/Player/`
- [ ] `PlayerViewModelTests` is `@MainActor struct`
- [ ] Uses `AudioPlayerServiceSpy` (new helper) — never `AVPlayer` or `AVAudioPlayerService`
- [ ] `makeSUT()` returns `(sut: PlayerViewModel, spy: AudioPlayerServiceSpy)`
- [ ] `onAppear_callsPlay_withSongPreviewURL`
- [ ] `onAppear_whenNoPreviewURL_doesNotCallPlay`
- [ ] `onDisappear_callsStop`
- [ ] `didTapPlayPause_whenPlaying_callsPause`
- [ ] `didTapPlayPause_whenPaused_callsResume`
- [ ] `didTapForward_whenNextExists_popsAndPushesNextSong`
- [ ] `didTapForward_whenAtEnd_doesNothing`
- [ ] `didTapBackward_whenBeyondThreshold_seeksToZero`
- [ ] `didTapBackward_whenWithinThreshold_andPrevExists_popsAndPushesPrevSong`
- [ ] `didTapBackward_whenAtStart_seeksToZero`
- [ ] `didTapMoreOptions_presentsMoreOptionsSheet`
- [ ] `currentTimeFormatted_returnsCorrectString` (e.g. 90s → "1:30")
- [ ] `durationFormatted_returnsCorrectString`
- [ ] `artworkURL_replaces100x100With600x600`

### Non-Goals
- No scrubbing / interactive seek via drag on progress bar (display only)
- No SwiftData persistence for recently played (future track)
- No audio interruption handling (phone calls, alarms)
- No iOS 26 Observable AVPlayer APIs — use KVO/Combine, iOS 17+ compatible
- No shuffle / repeat functionality (button is a visual placeholder only)

---

## Tasks

### Task 1: Save Spec Documentation

Create `agent-os/specs/2026-04-12-1200-player-screen/` with plan.md, shape.md, standards.md, references.md, visuals/.

### Task 2: `AudioPlayerService` Protocol in TuneDomain

Add `TuneDomain/Services/AudioPlayerService.swift` with the protocol definition.

**Stories:** S1, S2, S3, S4, S7, S9
**ACs:** Domain / Protocol (all)

### Task 3: `AVAudioPlayerService` + `AudioPlayerServiceSpy`

Create `TuneUI/Player/AVAudioPlayerService.swift` (concrete AVPlayer wrapper). Create `TuneFlowTests/Helpers/AudioPlayerServiceSpy.swift` (test double).

**Stories:** S1, S2, S3, S4, S7
**ACs:** AVAudioPlayerService (all), `AudioPlayerServiceSpy` helper

### Task 4: `PlayerViewModel` + Tests

Create `TuneUI/Player/PlayerViewModel.swift`. Write `TuneFlowTests/Player/PlayerViewModelTests.swift` covering all listed test cases.

**Stories:** S1, S2, S3, S4, S5, S6, S7, S8, S9
**ACs:** PlayerViewModel (all), Testing — all `PlayerViewModelTests` cases

### Task 5: `PlayerView` + `PlayerComposer` + Navigation Wiring

Create `TuneUI/Player/PlayerView.swift` matching mockup and DESIGN.md. Create `TuneUI/Composers/PlayerComposer.swift`. Update `RootView` to replace placeholder. Update `SongsViewModel.songTapped(_:)` to pass queue and index.

**Stories:** S1, S2, S3, S4, S5, S6, S7, S8, S9
**ACs:** PlayerView (all), PlayerComposer (all), Navigation wiring (all)

### Task 6: Validate All ACs

Walk through every acceptance criterion and verify it has been implemented and tested. Run `swift test` in `Packages/TuneDomain`. Tell user to run `xcodebuild test -scheme TuneFlow -destination 'platform=iOS Simulator,name=iPhone 16'` manually.

**ACs:** All
