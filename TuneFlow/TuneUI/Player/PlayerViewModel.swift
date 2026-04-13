import AVFoundation
import TuneDomain

@MainActor
@Observable
final class PlayerViewModel {
    let song: Song
    let audioService: any AudioPlayerService

    private(set) var isRepeatOn: Bool = false
    private(set) var isShuffleOn: Bool = false

    var currentTime: TimeInterval { audioService.currentTime }
    var duration: TimeInterval { audioService.duration }
    var progress: Double { audioService.progress }
    var currentTimeFormatted: String { formatTime(audioService.currentTime) }
    var durationFormatted: String { formatTime(audioService.duration) }

    var artworkURL: URL? {
        let original = song.artworkURL.absoluteString
        let scaled = original.replacingOccurrences(of: "100x100", with: "600x600")
        return URL(string: scaled)
    }

    /// Exposed so the view can observe AVPlayer state directly via iOS 26 Observable APIs.
    var avPlayer: AVPlayer? { (audioService as? AVAudioPlayerService)?.player }

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
        guard let url = song.previewURL else { return }
        audioService.play(url: url)
    }

    func onDisappear() {
        audioService.stop()
    }

    // MARK: - Transport Controls

    func didTapPlayPause() {
        if audioService.isPlaying {
            audioService.pause()
        } else {
            audioService.resume()
        }
    }

    func didTapBackward() {
        if audioService.currentTime > 3 {
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
        let nextIndex: Int
        if isShuffleOn && queue.count > 1 {
            var random: Int
            repeat {
                random = Int.random(in: 0..<queue.count)
            } while random == currentIndex
            nextIndex = random
        } else {
            nextIndex = currentIndex + 1
        }

        guard nextIndex < queue.count else { return }
        router.pop()
        let next = queue[nextIndex]
        router.push(.player(next, queue: queue, currentIndex: nextIndex))
    }

    func didTapRepeat() {
        isRepeatOn.toggle()
        (audioService as? AVAudioPlayerService)?.isRepeatOn = isRepeatOn
    }

    func didTapShuffle() {
        isShuffleOn.toggle()
    }

    func didTapMoreOptions() {
        router.present(.moreOptions(song))
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
