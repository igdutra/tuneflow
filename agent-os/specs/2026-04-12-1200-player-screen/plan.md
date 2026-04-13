# Track 5 — Player Screen — Plan

> Commit Rule: Immediately after completing each task, create exactly one commit before starting the next task. Never batch multiple tasks into one commit and never leave a completed task uncommitted. Commit message must be a single line: task title + key files touched - No Co-Authored-By trailer.

## Overview

Implement the Player screen that opens when a song is tapped. The screen streams the song's iTunes 30-second preview URL using `AVPlayer`, displays large album artwork, track title, artist name, a live progress bar with timestamps, and transport controls (previous / play-pause / next / repeat). The ViewModel owns the `AVPlayer` instance and exposes it directly to the view — iOS 26's Observable AVFoundation APIs mean SwiftUI can observe `player.timeControlStatus` and other state properties without KVO or Combine. Only `addPeriodicTimeObserver` is still required for continuous time tracking.

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

### S5: Next song navigation

Given the user arrived at the Player from a list of songs (queue)
When they tap the next button
Then the app navigates to the next song in the queue

### S6: Backward skip restarts or goes to previous

Given the user is on the Player screen
When they tap the previous button
Then: if more than 3 seconds into the song — the song restarts from the beginning; if 3 seconds or less — the app navigates to the previous song in the queue (or restarts if at the start)

### S7: Player screen dismissed / navigated away

Given the user is on the Player screen
When they navigate back (system back or pop)
Then playback stops cleanly — no audio continues in the background

### S8: More Options from Player

Given the user is on the Player screen
When they tap the ellipsis (…) button
Then the MoreOptionsView.swift bottom sheet appears for the current song

### S9: Song with no preview URL

Given the user taps a song that has no preview URL
When the Player screen appears
Then the screen renders correctly (artwork, title, artist) with playback controls disabled or inert — no crash

### S10: Repeat mode

Given the user is on the Player screen
When they tap the repeat button
Then repeat mode toggles on — when the 30-second preview ends it automatically restarts instead of stopping — tapping again turns repeat off

### S11: Shuffle

Given the user is on the Player screen and has a queue of songs
When they tap the shuffle button (or it is already on from the Songs screen)
Then tapping next navigates to a random song from the queue instead of the sequential next song; tapping again disables shuffle and resumes sequential order

---

## Acceptance Criteria

### iOS 26 Observable AVFoundation Setup
- [ ] `AVPlayer.isObservationEnabled = true` is set in `TuneFlowApp` before any player is created
- [ ] No KVO `.publisher(for: \.)` or Combine subscriptions used for player state observation — use direct property access in SwiftUI

### Domain / Protocol
- [ ] `AudioPlayerService` protocol added to `TuneDomain/Services/` with: `play(url:)`, `pause()`, `resume()`, `stop()`, `seek(to:)`, `var isPlaying: Bool`, `var currentTime: TimeInterval`, `var duration: TimeInterval`, `var progress: Double`
- [ ] Protocol is `AnyObject & Sendable`
- [ ] No AVFoundation import in `TuneDomain`

### AVAudioPlayerService (concrete implementation)
- [ ] `AVAudioPlayerService` lives in `TuneUI/Player/` (infrastructure, not TuneDomain)
- [ ] Exposes `var player: AVPlayer?` — view observes this directly via iOS 26 Observable APIs
- [ ] Player is created lazily in `play(url:)`, not in init
- [ ] Configures `AVAudioSession` with `.playback` category before first play
- [ ] Uses `addPeriodicTimeObserver` with 0.25s interval, `preferredTimescale: 600` for `currentTime` and `progress` (still required — Observation doesn't cover continuous time)
- [ ] Guards `duration.isFinite && duration > 0` before updating progress
- [ ] Observes `AVPlayerItemDidPlayToEndTime` — when fired: if repeat on → `seek(to: 0)` + `play()`; otherwise → stop
- [ ] Removes time observer token in `stop()` AND `deinit` (safety net)
- [ ] `stop()` is idempotent

### PlayerViewModel
- [ ] `PlayerViewModel` is `@MainActor @Observable final class`
- [ ] Receives `Song`, `queue: [Song]`, `currentIndex: Int`, `audioService: AVAudioPlayerService`, `router: AppRouter` via init
- [ ] Exposes `audioService` (or its `player`) to the view for direct Observable observation of `timeControlStatus`
- [ ] Exposes `currentTime: TimeInterval` and `progress: Double` (driven by `addPeriodicTimeObserver` via service)
- [ ] Exposes `duration: TimeInterval`
- [ ] Exposes computed: `currentTimeFormatted`, `durationFormatted` (format: `M:SS`)
- [ ] Exposes `artworkURL: URL?` — replaces `100x100` with `600x600` in artwork URL string
- [ ] Exposes `isRepeatOn: Bool` — toggled by `didTapRepeat()`
- [ ] Exposes `isShuffleOn: Bool` — toggled by `didTapShuffle()`
- [ ] `onAppear()` — calls `audioService.play(url:)` with `song.previewURL`; guards nil safely
- [ ] `onDisappear()` — calls `audioService.stop()`
- [ ] `didTapPlayPause()` — reads `audioService.player?.timeControlStatus` to determine state; calls `pause()` or `resume()`
- [ ] `didTapBackward()` — if `currentTime > 3`: seek to zero; else if `prevIndex >= 0`: pop + push previous; else seek to zero
- [ ] `didTapForward()` — if `isShuffleOn`: pick random index ≠ `currentIndex`; else next sequential; pop + push new song
- [ ] `didTapRepeat()` — toggles `isRepeatOn`; passes state to service so end-of-playback handler knows what to do
- [ ] `didTapShuffle()` — toggles `isShuffleOn`
- [ ] `didTapMoreOptions()` — `router.present(.moreOptions(song))`
- [ ] `@ObservationIgnored` on `router`, `audioService`, `queue`, `currentIndex`

### PlayerView
- [ ] `PlayerView` uses `@Bindable var viewModel: PlayerViewModel`
- [ ] `isPlaying` derived directly from `viewModel.audioService.player?.timeControlStatus == .playing` — no stored bool
- [ ] Play button disabled when `player?.currentItem?.status != .readyToPlay`
- [ ] Matches mockup: pure `#000000` background, centered 280pt square album artwork (cornerRadius 16pt), track title (32pt Bold #FFFFFF), artist (16pt Regular #FFFFFF @ 70%)
- [ ] Repeat and shuffle buttons visible in song info row; tinted white when active, gray when inactive
- [ ] Progress bar: track `#3A3A3C`, fill `#FFFFFF`, thumb `#FFFFFF` 12pt circle; elapsed left, remaining right (13pt #FFFFFF @ 60%)
- [ ] Transport controls: backward (28pt), play/pause (56pt circle glass), forward (28pt)
- [ ] Play button: `#3A3A3C` + `.ultraThinMaterial`, 1pt `rgba(255,255,255,0.10)` border
- [ ] Nav bar: compact centered album/collection title (17pt Semibold #FFFFFF), ellipsis button right
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
- [ ] `SongsViewModel.songTapped(_:)` pushes `.player(song, queue: songs, index: i)` — or equivalent — so the player knows its queue position
- [ ] `AppRoute.player` carries `Song`, `queue: [Song]`, `currentIndex: Int`

### Testing — `TuneFlowTests/Player/`
- [ ] `PlayerViewModelTests` is `@MainActor struct`
- [ ] Uses `AudioPlayerServiceSpy` — never `AVPlayer` or `AVAudioPlayerService`
- [ ] `makeSUT()` returns `(sut: PlayerViewModel, spy: AudioPlayerServiceSpy)`
- [ ] `onAppear_callsPlay_withSongPreviewURL`
- [ ] `onAppear_whenNoPreviewURL_doesNotCallPlay`
- [ ] `onDisappear_callsStop`
- [ ] `didTapPlayPause_whenPlaying_callsPause`
- [ ] `didTapPlayPause_whenPaused_callsResume`
- [ ] `didTapForward_sequentialMode_popsAndPushesNextSong`
- [ ] `didTapForward_atEndOfQueue_doesNothing`
- [ ] `didTapForward_shuffleOn_pushesRandomSong`
- [ ] `didTapBackward_whenBeyondThreshold_seeksToZero`
- [ ] `didTapBackward_whenWithinThreshold_andPrevExists_popsAndPushesPrevSong`
- [ ] `didTapBackward_whenAtStart_seeksToZero`
- [ ] `didTapRepeat_togglesRepeatState`
- [ ] `didTapShuffle_togglesShuffleState`
- [ ] `didTapMoreOptions_presentsMoreOptionsSheet`
- [ ] `currentTimeFormatted_returnsCorrectString` (e.g. 90s → "1:30")
- [ ] `durationFormatted_returnsCorrectString`
- [ ] `artworkURL_replaces100x100With600x600`

### Non-Goals
- No scrubbing / interactive seek via drag on progress bar (display only)
- No SwiftData persistence for recently played (future track)
- No audio interruption handling (phone calls, alarms)
- No `AVQueuePlayer` — navigation between songs uses the router (pop + push)

---

## Tasks

### Task 1: Save Spec Documentation

Create `agent-os/specs/2026-04-12-1200-player-screen/` with plan.md, shape.md, standards.md, references.md, visuals/.

-> Commit immediately after completing this task, following the commit rule.

### Task 2: `AudioPlayerService` Protocol in TuneDomain + App Init

Add `TuneDomain/Services/AudioPlayerService.swift`. Set `AVPlayer.isObservationEnabled = true` in `TuneFlowApp` init. Update `AppRoute.player` to carry queue and index.

**Stories:** S1, S2, S3, S4, S7, S9
**ACs:** iOS 26 Observable Setup (all), Domain / Protocol (all), Navigation wiring — AppRoute change

-> Commit immediately after completing this task, following the commit rule.

### Task 3: `AVAudioPlayerService` + `AudioPlayerServiceSpy`

Create `TuneUI/Player/AVAudioPlayerService.swift`. Create `TuneFlowTests/Helpers/AudioPlayerServiceSpy.swift`.

**Stories:** S1, S2, S3, S4, S7, S10
**ACs:** AVAudioPlayerService (all), AudioPlayerServiceSpy helper

-> Commit immediately after completing this task, following the commit rule.

### Task 4: `PlayerViewModel` + Tests

Create `TuneUI/Player/PlayerViewModel.swift`. Write `TuneFlowTests/Player/PlayerViewModelTests.swift` covering all listed test cases.

**Stories:** S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11
**ACs:** PlayerViewModel (all), Testing — all PlayerViewModelTests cases

-> Commit immediately after completing this task, following the commit rule.

### Task 5: `PlayerView` + `PlayerComposer` + Navigation Wiring

Create `TuneUI/Player/PlayerView.swift` matching mockup and DESIGN.md. Create `TuneUI/Composers/PlayerComposer.swift`. Update `RootView` to replace placeholder. Update `SongsViewModel.songTapped(_:)` to pass queue and index.

**Stories:** S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11
**ACs:** PlayerView (all), PlayerComposer (all), Navigation wiring (all)

-> Commit immediately after completing this task, following the commit rule.

### Task 6: Validate All ACs

Walk through every acceptance criterion and verify it has been implemented and tested. Run `swift test` in `Packages/TuneDomain`. Tell user to run `xcodebuild test -scheme TuneFlow -destination 'platform=iOS Simulator,name=iPhone 16'` manually.

**ACs:** All
