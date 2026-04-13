import TuneDomain
import SwiftUI

/// iOS 26 Observable pattern with protocol-wrapped service:
/// Since `AudioPlayerService` is a protocol (not a concrete `AVPlayer`), SwiftUI cannot observe through
/// the protocol boundary directly. Instead, we hold stored observable state properties that the service
/// updates via callback. This is correct iOS 26 design — if we exposed `AVPlayer` directly in the
/// ViewModel, we could observe `player.timeControlStatus` live with no callback needed. But with a
/// protocol service layer, the callback bridge is the proper pattern.
@MainActor
@Observable
final class PlayerViewModel {
    let song: Song

    // MARK: - Stored observable state (fed by service callback)

    private(set) var isPlaying: Bool = false
    private(set) var isReadyToPlay: Bool = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var progress: Double = 0
    // TODO: Deferred — shuffle and repeat require persistent state across navigations
    // For now, these are disabled in the view with visual feedback (grayed out + disabled)
    private(set) var isRepeatOn: Bool = false
    private(set) var isShuffleOn: Bool = false

    // MARK: - Computed display

    var currentTimeFormatted: String { formatTime(currentTime) }
    var remainingTimeFormatted: String { formatTime(max(0, duration - currentTime)) }
    var durationFormatted: String { formatTime(duration) }

    var artworkURL: URL? {
        let original = song.artworkURL.absoluteString
        let scaled = original.replacingOccurrences(of: "100x100", with: "600x600")
        return URL(string: scaled)
    }

    // MARK: - Private

    @ObservationIgnored let audioService: any AudioPlayerService
    @ObservationIgnored private let router: AppRouter
    @ObservationIgnored private let queue: [Song]
    @ObservationIgnored private let currentIndex: Int
    @ObservationIgnored private let recentlyPlayedRepository: any RecentlyPlayedRepository
    @ObservationIgnored private var didSaveToRecentlyPlayed = false

    // MARK: - Task Launcher
    //
    // Why this exists — the testability problem with fire-and-forget Tasks:
    //
    // `apply()` needs to kick off async work (saving to recently played) from a synchronous
    // context (the `onStateChange` callback). The natural Swift pattern is an unstructured
    // `Task { await ... }`. However, this creates a fundamental testing problem:
    //
    //   - The unstructured Task body is enqueued on the cooperative scheduler.
    //   - Swift's cooperative thread pool is intentionally non-deterministic.
    //   - Tests on `@MainActor` that call `await Task.yield()` are NOT guaranteed to
    //     resume AFTER the enqueued Task body has run — `Task.yield()` is a single
    //     cooperative suspension, not a barrier across independently-scheduled tasks.
    //   - Result: `repoSpy.saveCallCount` reads 0 instead of 1 ~1 in 5 runs (flaky test).
    //
    // The fix — inject the task-spawning mechanism:
    //
    //   By making `launchTask` a stored property with a default that does the normal
    //   `Task { await body() }`, we keep identical production behaviour while giving
    //   tests the ability to swap in a custom launcher. Tests override it to advance
    //   execution deterministically — e.g., by using `withMainSerialExecutor` from
    //   swift-concurrency-extras, or simply by letting it run as a normal Task and
    //   using a spy hook (onSave) to synchronise assertions.
    //
    // Why NOT use `withCheckedContinuation` instead:
    //   - `CheckedContinuation` is non-Sendable, causing Swift 6 friction.
    //   - Resuming it 0 times hangs the test forever; resuming it 2+ times crashes.
    //   - There is a confirmed Swift runtime bug (SR-14802) where Tasks resuming
    //     continuations can silently hang under certain scheduler conditions.
    //
    // Why NOT use Swift Testing's `confirmation()` instead:
    //   - `confirmation()` does NOT block/timeout-wait for `confirm()` to be called.
    //     It only checks whether `confirm()` was called before the body closure exits.
    //     For a fire-and-forget Task, the closure exits before the Task runs — same race.
    //     (See open swift-testing issue #978.)
    //
    // References:
    //   - Swift Forums: "Reliably testing code that adopts Swift Concurrency"
    //     forums.swift.org/t/reliably-testing-code-that-adopts-swift-concurrency/57304
    //   - Point-Free: "Reliably testing async code in Swift"
    //     pointfree.co/blog/posts/110-reliably-testing-async-code-in-swift
    //   - SR-14802: github.com/swiftlang/swift/issues/57150
    //   - swift-testing issue #978: github.com/swiftlang/swift-testing/issues/978
    @ObservationIgnored var launchTask: (@MainActor @Sendable (@escaping @Sendable () async -> Void) -> Void) = { body in
        Task { await body() }
    }

    init(
        song: Song,
        queue: [Song],
        currentIndex: Int,
        audioService: any AudioPlayerService,
        recentlyPlayedRepository: any RecentlyPlayedRepository,
        router: AppRouter
    ) {
        self.song = song
        self.queue = queue
        self.currentIndex = currentIndex
        self.audioService = audioService
        self.recentlyPlayedRepository = recentlyPlayedRepository
        self.router = router
    }

    // MARK: - Lifecycle

    func onAppear() {
        audioService.onStateChange = { [weak self] state in
            guard let self else { return }
            self.apply(state)
        }
        guard let url = song.previewURL else { return }
        audioService.play(url: url)
    }

    func onDisappear() {
        audioService.onStateChange = nil
        audioService.stop()
    }

    // MARK: - Transport Controls

    func didTapPlayPause() {
        if isPlaying {
            audioService.pause()
        } else {
            audioService.resume()
        }
    }

    func didTapBackward() {
        // TODO: Deferred — button is disabled in the view pending queue navigation implementation
    }

    func didTapForward() {
        // TODO: Deferred — button is disabled in the view pending queue navigation implementation
    }

    func didTapRepeat() {
        // Deferred — button is disabled in the view
    }

    func didTapShuffle() {
        // Deferred — button is disabled in the view
    }

    func didTapMoreOptions() {
        router.present(.moreOptions(song))
    }

    // MARK: - State Application

    private func apply(_ state: AudioPlayerState) {
        if !didSaveToRecentlyPlayed && state.isReadyToPlay {
            didSaveToRecentlyPlayed = true
            launchTask { [weak self] in
                guard let self else { return }
                try? await recentlyPlayedRepository.save(song)
            }
        }
        isPlaying = state.isPlaying
        isReadyToPlay = state.isReadyToPlay
        currentTime = state.currentTime
        duration = state.duration
        progress = state.progress
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return "\(m):\(String(format: "%02d", s))"
    }
}
