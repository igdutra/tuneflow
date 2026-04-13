# Standards for Track 5 — Player Screen

The following standards apply to this work.

---

## swift/audio-player

**Core Decision: AVPlayer, not AVAudioPlayer**

iTunes preview URLs are remote `.m4a` streams — `AVAudioPlayer` only works with local files. Always use `AVPlayer`.

**iOS 26 Observable AVFoundation — Mandatory**

This app targets iOS 26 only. AVPlayer/AVPlayerItem conform to `Observable` starting iOS 26.

```swift
// In TuneFlowApp — before any player is created
AVPlayer.isObservationEnabled = true
```

- Global flag, set once at app launch, never changed afterward
- After opt-in: observe `player.timeControlStatus`, `player.currentItem?.status`, `player.rate` directly in SwiftUI — no KVO, no Combine
- `addPeriodicTimeObserver` is **still required** for continuous time tracking — Observation covers state, not a time stream
- `NotificationCenter` is still used for `AVPlayerItemDidPlayToEndTime`

**Layer Architecture**

```
PlayerView (thin, declarative — observes AVPlayer directly via iOS 26 APIs)
    ↓ reads from
PlayerViewModel (@Observable, @MainActor — owns service, exposes it to view)
    ↓ depends on protocol
AudioPlayerService (protocol in TuneDomain — the test seam)
    ↓ implemented by
AVAudioPlayerService (wraps AVPlayer, lives in TuneUI/Player/)
```

**AudioPlayerService Protocol (TuneDomain)**

```swift
public protocol AudioPlayerService: AnyObject, Sendable {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var progress: Double { get }

    func play(url: URL)
    func pause()
    func resume()
    func stop()
    func seek(to time: TimeInterval)
}
```

**AVAudioPlayerService — Key Rules (iOS 26)**

- Expose `var player: AVPlayer?` so the view can observe state directly
- Player created in `play(url:)`, not in `init` (defer creation per Apple guidance)
- Configure `AVAudioSession` with `.playback` category before first play
- `addPeriodicTimeObserver`: 0.25s interval, `preferredTimescale: 600`
- Guard `duration.isFinite && duration > 0` before updating `progress`
- **No Combine** (`cancellables`, `.sink`, `.publisher(for:)`) — use Observation and NotificationCenter only
- `NotificationCenter` for `AVPlayerItemDidPlayToEndTime`: if repeat on → seek to zero + play; else stop
- Remove time observer token in `stop()` AND `deinit`
- `stop()` is idempotent

**PlayerViewModel Shape**

```swift
@MainActor
@Observable
final class PlayerViewModel {
    let song: Song
    let audioService: AVAudioPlayerService  // exposed — view observes player directly

    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var progress: Double = 0
    private(set) var isRepeatOn: Bool = false
    private(set) var isShuffleOn: Bool = false

    var currentTimeFormatted: String { formatTime(currentTime) }
    var durationFormatted: String { formatTime(duration) }
    var artworkURL: URL? { /* replace 100x100 → 600x600 */ }

    @ObservationIgnored private let router: AppRouter
    @ObservationIgnored private let queue: [Song]
    @ObservationIgnored private let currentIndex: Int
}
```

- `isPlaying` in the **view** is: `viewModel.audioService.player?.timeControlStatus == .playing` — not a stored bool
- Backward skip threshold: `currentTime > 3` → seek to zero; otherwise navigate to prev
- Shuffle: `didTapForward()` picks random index ≠ currentIndex when `isShuffleOn`

**Testing: AudioPlayerServiceSpy**

```swift
final class AudioPlayerServiceSpy: AudioPlayerService {
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 30
    var progress: Double = 0

    private(set) var playCallCount = 0
    private(set) var playCalledWithURL: URL?
    private(set) var pauseCallCount = 0
    private(set) var resumeCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var seekCalledWithTime: TimeInterval?

    func play(url: URL) { playCallCount += 1; playCalledWithURL = url; isPlaying = true }
    func pause()        { pauseCallCount += 1; isPlaying = false }
    func resume()       { resumeCallCount += 1; isPlaying = true }
    func stop()         { stopCallCount += 1; isPlaying = false }
    func seek(to time: TimeInterval) { seekCalledWithTime = time }
}
```

**What to test in PlayerViewModelTests**

- `onAppear` calls `play(url:)` with the song's `previewURL`
- `onAppear` with nil previewURL does NOT call play
- `onDisappear` calls `stop()`
- `didTapPlayPause` calls `pause()` when playing, `resume()` when paused
- `didTapForward` in sequential mode pops + pushes next song
- `didTapForward` at end of queue does nothing
- `didTapForward` in shuffle mode pushes a random song (≠ current)
- `didTapBackward` beyond threshold seeks to zero
- `didTapBackward` within threshold + prev exists → pop + push prev
- `didTapBackward` at start → seeks to zero
- `didTapRepeat` toggles `isRepeatOn`
- `didTapShuffle` toggles `isShuffleOn`
- `didTapMoreOptions` presents `.moreOptions(song)`
- Formatted time strings are correct
- `artworkURL` replaces `100x100` with `600x600`

---

## swift/module-composition (relevant excerpt)

- `TuneDomain` owns `AudioPlayerService` protocol — no AVFoundation imports
- `TuneUI` owns `AVAudioPlayerService`, `PlayerViewModel`, `PlayerView`, `PlayerComposer`
- Composer pattern: `@MainActor enum PlayerComposer` assembles and returns the view

---

## swift/swiftui (relevant excerpt)

- `@Observable` + `@MainActor` on all ViewModels
- View uses `@Bindable var viewModel: PlayerViewModel`
- `onAppear`/`onDisappear` for player lifecycle — NOT `.task`
- `Button` not `onTapGesture` for all controls
- Pass method references to child views, not inline closures

---

## swift/testing (relevant excerpt)

- `import Testing` only
- `@MainActor struct PlayerViewModelTests`
- `makeSUT()` returns typed `SUTBundle` tuple with `source: SourceLocation = #_sourceLocation`
- Spy records calls; stub controls return values
- `#expect` default; `#require` for prerequisites
- Test naming: `subject_condition_expectedOutcome`
