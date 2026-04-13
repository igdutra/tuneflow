# Standards for Track 5 — Player Screen

The following standards apply to this work.

---

## swift/audio-player

**Core Decision: AVPlayer, not AVAudioPlayer**

iTunes preview URLs are remote `.m4a` streams — `AVAudioPlayer` only works with local files. Always use `AVPlayer`.

**Layer Architecture**

```
PlayerView (thin, declarative)
    ↓ reads state from
PlayerViewModel (@Observable, @MainActor)
    ↓ depends on protocol
AudioPlayerService (protocol, defined in TuneDomain)
    ↓ implemented by
AVAudioPlayerService (wraps AVPlayer, lives in TuneUI)
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

**AVAudioPlayerService Key Rules**

- Configure `AVAudioSession` with `.playback` category before first play
- `addPeriodicTimeObserver` with 0.25s interval, `preferredTimescale: 600`
- Guard `duration.isFinite && duration > 0` before updating progress
- Observe `AVPlayerItemDidPlayToEndTime` via `NotificationCenter` publisher
- Remove time observer in `stop()` AND `deinit` (safety net)
- `stop()` is idempotent

**PlayerViewModel Shape**

- `@MainActor @Observable final class`
- Never imports `AVFoundation`
- `onAppear()` / `onDisappear()` for lifecycle (not `.task`)
- Backward skip threshold: `currentTime > 3` → seek to zero

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

---

## swift/module-composition (excerpt — relevant to Player)

- `TuneDomain` owns protocols and domain models — `AudioPlayerService` goes here
- `TuneUI` owns ViewModels, Views, Composers, and concrete service implementations
- `TuneUI` must not expose AVFoundation types upward
- Each screen gets a dedicated `Composer` that assembles view + view model
- `AudioPlayerService` is a **Service** (not Repository) — use `Service` naming per the standard

---

## swift/swiftui (excerpt — relevant to Player)

- `@Observable` + `@MainActor` on all ViewModels — mandatory
- View uses `@Bindable var viewModel: PlayerViewModel` (injected, needs bindings)
- `onAppear`/`onDisappear` for player lifecycle — NOT `.task` (must stop on disappear)
- Pass method references to child views, not inline closures
- `Button` not `onTapGesture` for all interactive elements
- No business logic in view body

---

## swift/testing (excerpt — relevant to Player)

- `import Testing` only — no XCTest
- `@MainActor struct PlayerViewModelTests` (ViewModel is @MainActor)
- `makeSUT()` returns typed `SUTBundle` tuple
- Spy for `AudioPlayerService` — records calls, stubs state
- `source: SourceLocation = #_sourceLocation` in `makeSUT()` signature
- `#expect` default; `#require` for prerequisites
- Test naming: `subject_condition_expectedOutcome`
