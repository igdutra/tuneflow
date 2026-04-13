# Audio Player Standard

**Target: iOS 26 only.**

## Core Decision: AVPlayer, not AVAudioPlayer

iTunes preview URLs are remote `.m4a` streams — `AVAudioPlayer` only works with local files. Always use `AVPlayer`.

---

## iOS 26: Observable AVFoundation

Starting iOS 26, AVPlayer/AVPlayerItem conform to `Observable`. This replaces KVO and Combine for state observation.

**Opt-in once at app launch — before any player is created:**

```swift
// TuneFlowApp.swift
AVPlayer.isObservationEnabled = true
```

This is a global flag. Set it in the `App` struct or before any playback object is instantiated. Changing it after creating players throws an exception.

**What Observation covers (observe directly in SwiftUI):**
- `player.timeControlStatus` — `.playing`, `.paused`, `.waitingToPlayAtSpecifiedRate`
- `player.currentItem?.status` — `.readyToPlay`, `.failed`, `.unknown`
- `player.rate`
- `player.currentItem`

**What still requires `addPeriodicTimeObserver`:**
- Continuous `currentTime` / `progress` tracking — Observation only covers discrete state, not a stream of time values

**What still requires `NotificationCenter`:**
- `AVPlayerItemDidPlayToEndTime` — playback end detection

**No Combine.** No KVO `.publisher(for:)`. No `cancellables` set. iOS 26 target means Observation is the only state observation mechanism needed.

---

## Layer Architecture

```
PlayerView (thin — observes AVPlayer directly via iOS 26 Observable APIs)
    ↓ reads from
PlayerViewModel (@Observable, @MainActor — owns service, exposes it to view)
    ↓ depends on protocol
AudioPlayerService (protocol in TuneDomain — the test seam)
    ↓ implemented by
AVAudioPlayerService (wraps AVPlayer, lives in TuneUI/Player/)
```

---

## AudioPlayerService Protocol (TuneDomain)

```swift
// TuneDomain/Services/AudioPlayerService.swift
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

- `AnyObject` constraint required — protocol is used as a class type in the ViewModel
- No AVFoundation import in `TuneDomain`

---

## AVAudioPlayerService (TuneUI — concrete, wraps AVPlayer)

**Expose the player for direct view observation:**

```swift
// View reads player.timeControlStatus directly — no stored isPlaying bool needed
private(set) var player: AVPlayer?
```

**Defer player creation to `play(url:)`** — do not create in `init`. Per Apple guidance, avoid side effects at initialization time.

**AVAudioSession** — configure once before first play:

```swift
try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
try AVAudioSession.sharedInstance().setActive(true)
```

**Periodic time observer** — still required for continuous time tracking:

```swift
let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
    let duration = self?.player?.currentItem?.duration.seconds ?? 0
    guard duration.isFinite && duration > 0 else { return }
    self?.currentTime = time.seconds
    self?.progress = time.seconds / duration
}
```

**Playback end** — NotificationCenter (still required):

```swift
NotificationCenter.default.addObserver(
    forName: AVPlayerItem.didPlayToEndTimeNotification,
    object: playerItem,
    queue: .main
) { [weak self] _ in
    guard let self else { return }
    if isRepeatOn {
        player?.seek(to: .zero)
        player?.play()
    } else {
        stop()
    }
}
```

**Cleanup** — remove time observer before releasing:

```swift
func stop() {
    player?.pause()
    if let token = timeObserverToken, let player {
        player.removeTimeObserver(token)
        timeObserverToken = nil
    }
    player = nil
    isPlaying = false
}
```

`stop()` must be idempotent. Also call it in `deinit` as a safety net.

**Artwork URL** — iTunes returns 100×100; replace in ViewModel (not service):

```swift
urlString.replacingOccurrences(of: "100x100", with: "600x600")
```

---

## PlayerViewModel Shape

```swift
@MainActor
@Observable
final class PlayerViewModel {
    let song: Song
    let audioService: AVAudioPlayerService  // exposed — view reads player.timeControlStatus

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
    @ObservationIgnored private var currentIndex: Int

    init(song: Song, queue: [Song], currentIndex: Int,
         audioService: AVAudioPlayerService, router: AppRouter) { ... }

    func onAppear() { /* play */ }
    func onDisappear() { /* stop */ }
    func didTapPlayPause() { /* toggle via player.timeControlStatus */ }
    func didTapForward() { /* sequential or random when shuffle on */ }
    func didTapBackward() { /* >3s → seek to zero; else → prev */ }
    func didTapRepeat() { isRepeatOn.toggle() }
    func didTapShuffle() { isShuffleOn.toggle() }
    func didTapMoreOptions() { router.present(.moreOptions(song)) }
}
```

- ViewModel never imports `AVFoundation`
- `isPlaying` in the **view** = `viewModel.audioService.player?.timeControlStatus == .playing`
- `@ObservationIgnored` on non-UI internals: router, audioService (when not directly observed by view), queue, currentIndex

**Backward skip rule:**
```
currentTime > 3s  →  seek to zero (restart)
currentTime ≤ 3s  →  navigate to previous; if at start, seek to zero
```

**Shuffle rule:**
```
isShuffleOn == true  →  pick random index ≠ currentIndex from queue
isShuffleOn == false →  sequential next/prev
```

---

## Repeat & Shuffle

Both are ViewModel-level state flags passed to / read by the service's end-of-playback handler.

- **Repeat**: when `AVPlayerItemDidPlayToEndTime` fires and `isRepeatOn == true` → seek to `.zero` + play instead of stopping
- **Shuffle**: affects `didTapForward()` index selection only — not a separate AVPlayer API

---

## Composer Wiring

```swift
@MainActor
enum PlayerComposer {
    static func compose(
        song: Song,
        queue: [Song],
        currentIndex: Int,
        router: AppRouter
    ) -> some View {
        let service = AVAudioPlayerService()
        let viewModel = PlayerViewModel(
            song: song,
            queue: queue,
            currentIndex: currentIndex,
            audioService: service,
            router: router
        )
        return PlayerView(viewModel: viewModel)
    }
}
```

Service is created per-navigation inside the composer — not a global singleton.

---

## Testing

The `AudioPlayerService` protocol is the test seam. Use a spy — never instantiate `AVPlayer` in tests.

### AudioPlayerServiceSpy

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

### Test suite

```swift
@MainActor
struct PlayerViewModelTests {
    @Test func onAppear_callsPlay_withSongPreviewURL() { ... }
    @Test func onAppear_whenNoPreviewURL_doesNotCallPlay() { ... }
    @Test func onDisappear_callsStop() { ... }
    @Test func didTapPlayPause_whenPlaying_callsPause() { ... }
    @Test func didTapPlayPause_whenPaused_callsResume() { ... }
    @Test func didTapForward_sequentialMode_pushesNextSong() { ... }
    @Test func didTapForward_atEndOfQueue_doesNothing() { ... }
    @Test func didTapForward_shuffleOn_pushesRandomSong() { ... }
    @Test func didTapBackward_whenBeyondThreshold_seeksToZero() { ... }
    @Test func didTapBackward_whenWithinThreshold_andPrevExists_pushesPrevSong() { ... }
    @Test func didTapBackward_whenAtStart_seeksToZero() { ... }
    @Test func didTapRepeat_togglesRepeatOn() { ... }
    @Test func didTapShuffle_togglesShuffleOn() { ... }
    @Test func didTapMoreOptions_presentsSheet() { ... }
    @Test func currentTimeFormatted_returns_correctString() { ... }
    @Test func artworkURL_replaces100x100With600x600() { ... }
}
```

### What NOT to test in unit tests

- Actual audio output
- `AVAudioSession` configuration
- `addPeriodicTimeObserver` callbacks (test ViewModel reaction via spy state, not the AVFoundation plumbing)
- `AVPlayer.isObservationEnabled` (set at app init — not a ViewModel concern)

---

## Common Pitfalls

| Pitfall | Fix |
|---|---|
| Setting `isObservationEnabled` after creating a player | Set it in `TuneFlowApp` before any player init — it throws if changed late |
| Storing `isPlaying` as a bool on the ViewModel | Read `player.timeControlStatus` directly in SwiftUI — it's Observable now |
| Using Combine for state observation | iOS 26 target — use Observation. Only time observer and NotificationCenter still needed |
| Forgetting `removeTimeObserver` | Call in `stop()` AND `deinit` as safety net |
| Reading duration before buffered | Guard `duration.isFinite && duration > 0` |
| Skipping `AVAudioSession` setup | No sound on device (simulator works without it) |
| `[weak self]` missing in time observer closure | Retain cycle — always capture weak |
| Checking `isPlaying` via `player.rate` | Use `timeControlStatus` — rate can be non-zero while buffering |
