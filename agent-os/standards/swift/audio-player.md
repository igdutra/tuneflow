# Audio Player Standard

## Core Decision: AVPlayer, not AVAudioPlayer

iTunes preview URLs are remote `.m4a` streams — `AVAudioPlayer` only works with local files. Always use `AVPlayer`.

---

## Layer Architecture

```
PlayerView (thin, declarative)
    ↓ reads state from
PlayerViewModel (@Observable, @MainActor)
    ↓ depends on protocol
AudioPlayerService (protocol, defined in TuneDomain)
    ↓ implemented by
AVAudioPlayerService (wraps AVPlayer, lives in TuneUI)
```

The `AudioPlayerService` protocol lives in `TuneDomain`. The `AVAudioPlayerService` concrete type lives in `TuneUI` — it is an infrastructure detail, not a domain concern.

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

- Protocol is the only boundary `PlayerViewModel` sees — never `AVPlayer` directly
- `AnyObject` constraint allows `@Observable` conformance on the implementation
- Keep it minimal — only what the ViewModel actually needs

---

## AVAudioPlayerService (TuneUI — concrete, wraps AVPlayer)

Key implementation rules:

**AVAudioSession** — configure once before first play:
```swift
try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
try AVAudioSession.sharedInstance().setActive(true)
```
`.playback` category ignores the silent switch and routes audio through speakers.

**Periodic time observer** — use 0.25s interval, `preferredTimescale: 600`:
```swift
let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
    let duration = self?.player.currentItem?.duration.seconds ?? 0
    guard duration.isFinite && duration > 0 else { return }
    self?.currentTime = time.seconds
    self?.progress = time.seconds / duration
}
```
Always guard `duration.isFinite` — streaming items report `.indefinite` until buffered.

**Playback end** — use `NotificationCenter`, not delegation:
```swift
NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    .receive(on: DispatchQueue.main)
    .sink { [weak self] _ in
        self?.isPlaying = false
        self?.player?.seek(to: .zero)
    }
    .store(in: &cancellables)
```

**Cleanup** — always remove time observer before releasing:
```swift
func stop() {
    player?.pause()
    if let token = timeObserverToken, let player {
        player.removeTimeObserver(token)
        timeObserverToken = nil
    }
    cancellables.removeAll()
    player = nil
}
```
Call `stop()` from `deinit` as a safety net. Failing to remove the token causes crashes.

**Duration** — read from `AVPlayerItem.duration`, not a hardcoded 30s:
```swift
player.currentItem?.publisher(for: \.duration)
    .receive(on: DispatchQueue.main)
    .sink { [weak self] duration in
        guard duration.isFinite else { return }
        self?.duration = duration.seconds
    }
    .store(in: &cancellables)
```

**Artwork URL** — iTunes returns 100×100; replace for high-res:
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
    private let audioPlayer: AudioPlayerService

    private(set) var isPlaying: Bool = false
    private(set) var progress: Double = 0
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    var currentTimeFormatted: String { formatTime(currentTime) }
    var durationFormatted: String { formatTime(duration) }

    init(song: Song, audioPlayer: AudioPlayerService) {
        self.song = song
        self.audioPlayer = audioPlayer
    }

    func onAppear() { /* play */ }
    func onDisappear() { /* stop */ }
    func didTapPlayPause() { /* toggle */ }
    func didTapForward() { /* next in queue via router */ }
    func didTapBackward() { /* restart or prev: threshold 3s */ }
}
```

- ViewModel never imports `AVFoundation` — only `TuneDomain`
- `@ObservationIgnored` on internal bookkeeping: Combine cancellables, pagination cursors
- Use `onAppear`/`onDisappear` — not `.task` — because player lifecycle must stop on disappear

---

## Backward Skip Rule

```
currentTime > 3s  →  seek to zero (restart current song)
currentTime ≤ 3s  →  navigate to previous song in queue
```

This mirrors standard music player UX (Spotify, Apple Music).

---

## Composer Wiring (TuneFlowApp)

```swift
@MainActor
enum PlayerComposer {
    static func compose(
        song: Song,
        queue: [Song],
        audioPlayer: AudioPlayerService,
        recentlyPlayedRepository: RecentlyPlayedRepository
    ) -> some View {
        let viewModel = PlayerViewModel(
            song: song,
            queue: queue,
            audioPlayer: audioPlayer,
            recentlyPlayedRepository: recentlyPlayedRepository
        )
        return PlayerView(viewModel: viewModel)
    }
}
```

The `AVAudioPlayerService` instance is created once in `TuneFlowApp` and passed down — one player instance shared across navigation to prevent overlapping audio.

---

## Testing

The `AudioPlayerService` protocol is the test seam. Use a spy — never instantiate `AVPlayer` in tests.

### AudioPlayerServiceSpy

```swift
final class AudioPlayerServiceSpy: AudioPlayerService {
    // Stubbed state (tests set these directly)
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 30
    var progress: Double = 0

    // Recorded calls
    private(set) var playCallCount = 0
    private(set) var playCalledWithURL: URL?
    private(set) var pauseCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var seekCalledWithTime: TimeInterval?

    func play(url: URL) { playCallCount += 1; playCalledWithURL = url; isPlaying = true }
    func pause()        { pauseCallCount += 1; isPlaying = false }
    func resume()       { isPlaying = true }
    func stop()         { stopCallCount += 1; isPlaying = false }
    func seek(to time: TimeInterval) { seekCalledWithTime = time }
}
```

### ViewModel Test Suite Template

```swift
@MainActor
struct PlayerViewModelTests {

    @Test func onAppear_startsPlayback() {
        let (sut, spy) = makeSUT()

        sut.onAppear()

        #expect(spy.playCallCount == 1)
        #expect(spy.playCalledWithURL == Song.fixture.previewURL)
    }

    @Test func onDisappear_stopsPlayback() {
        let (sut, spy) = makeSUT()
        sut.onAppear()

        sut.onDisappear()

        #expect(spy.stopCallCount == 1)
    }

    @Test func didTapPlayPause_whenPlaying_pauses() {
        let (sut, spy) = makeSUT()
        spy.isPlaying = true

        sut.didTapPlayPause()

        #expect(spy.pauseCallCount == 1)
    }

    @Test func didTapBackward_whenBeyondThreshold_seeksToZero() {
        let (sut, spy) = makeSUT()
        spy.currentTime = 10

        sut.didTapBackward()

        #expect(spy.seekCalledWithTime == 0)
    }
}

private extension PlayerViewModelTests {
    typealias SUTBundle = (sut: PlayerViewModel, spy: AudioPlayerServiceSpy)

    func makeSUT(source: SourceLocation = #_sourceLocation) -> SUTBundle {
        let spy = AudioPlayerServiceSpy()
        let sut = PlayerViewModel(song: .fixture, audioPlayer: spy)
        _ = source
        return (sut, spy)
    }
}
```

### What to test

- `onAppear` calls `play(url:)` with the song's `previewURL`
- `onDisappear` calls `stop()`
- `didTapPlayPause` toggles between `pause()` and `resume()`
- `didTapBackward` seeks to zero when `currentTime > 3`, navigates back otherwise
- Computed display properties (`currentTimeFormatted`, `durationFormatted`) return correct strings
- Progress bar values clamp to `[0, 1]`

### What NOT to test in unit tests

- Actual audio output (no simulator required — test against the spy)
- `AVAudioSession` configuration (integration concern)
- `addPeriodicTimeObserver` callbacks (test the ViewModel's reaction to state changes via spy properties, not the AVFoundation plumbing)

---

## Common Pitfalls

| Pitfall | Fix |
|---|---|
| Forgetting `removeTimeObserver` | Call in `stop()` AND `deinit` as safety net |
| Reading duration before buffered | Guard `duration.isFinite && duration > 0` |
| Skipping `AVAudioSession` setup | No sound on device (simulator works fine without it) |
| `[weak self]` missing in closures | Retain cycle — always capture weak in observer callbacks |
| Creating multiple `AVPlayer` instances | One shared instance at app level; teardown before reuse |
| Checking `isPlaying` via `player.rate` | Use `timeControlStatus` — rate can be non-zero while buffering |
