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

    init(
        song: Song,
        queue: [Song],
        currentIndex: Int,
        audioService: any AudioPlayerService,
        router: AppRouter
    ) {
        self.song = song
        self.queue = queue
        self.currentIndex = currentIndex
        self.audioService = audioService
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
        if currentTime > 3 {
            audioService.seek(to: 0)
        } else {
            let prevIndex = currentIndex - 1
            if prevIndex >= 0 {
                router.pop()
                let prev = queue[prevIndex]
                router.push(.player(prev, queue: queue, currentIndex: prevIndex))
            } else {
                audioService.seek(to: 0)
            }
        }
    }

    func didTapForward() {
        // TODO: Shuffle is deferred (see didTapShuffle). For now, always go sequential.
        let nextIndex = currentIndex + 1

        guard nextIndex < queue.count else { return }
        router.pop()
        let next = queue[nextIndex]
        router.push(.player(next, queue: queue, currentIndex: nextIndex))
    }

    func didTapRepeat() {
        // TODO: Repeat functionality is deferred. Current issue: repeat state does not persist across
        // song navigations because each PlayerViewModel is fresh. Fix requires moving repeat state to
        // a persistent layer (service or router). See BUGFIX.md for full scope.
        // For now, button toggles locally but has no effect on playback.
        isRepeatOn.toggle()
    }

    func didTapShuffle() {
        // TODO: Shuffle functionality is deferred. Current issue: shuffle state resets on each song
        // navigation because each PlayerViewModel is fresh. Fix requires persistent state layer.
        // For now, button toggles locally but has no effect on next navigation.
        isShuffleOn.toggle()
    }

    func didTapMoreOptions() {
        router.present(.moreOptions(song))
    }

    // MARK: - State Application

    private func apply(_ state: AudioPlayerState) {
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
