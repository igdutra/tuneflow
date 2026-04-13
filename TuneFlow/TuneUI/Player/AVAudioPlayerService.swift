import AVFoundation
import TuneDomain

@MainActor
class AVAudioPlayerService: AudioPlayerService {

    // MARK: - Public

    private(set) var player: AVPlayer?
    private(set) var isPlaying: Bool = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var progress: Double = 0

    var isRepeatOn: Bool = false

    // MARK: - Private

    private var timeObserverToken: Any?

    // MARK: - AudioPlayerService

    nonisolated func play(url: URL) {
        Task { @MainActor in self._play(url: url) }
    }

    nonisolated func pause() {
        Task { @MainActor in self._pause() }
    }

    nonisolated func resume() {
        Task { @MainActor in self._resume() }
    }

    nonisolated func stop() {
        Task { @MainActor in self._stop() }
    }

    nonisolated func seek(to time: TimeInterval) {
        Task { @MainActor in self._seek(to: time) }
    }

    // MARK: - Private Implementation

    private func _play(url: URL) {
        _stop()
        configureAudioSession()
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        newPlayer.play()
        isPlaying = true
        addPeriodicTimeObserver(to: newPlayer)
        observePlaybackEnd(for: item)
    }

    private func _pause() {
        player?.pause()
        isPlaying = false
    }

    private func _resume() {
        player?.play()
        isPlaying = true
    }

    private func _stop() {
        removeTimeObserver()
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        progress = 0
    }

    private func _seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
    }

    // MARK: - Time Observer

    private func addPeriodicTimeObserver(to avPlayer: AVPlayer) {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        let token = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
                let total = avPlayer.currentItem?.duration.seconds ?? 0
                if total.isFinite && total > 0 {
                    self.duration = total
                    self.progress = self.currentTime / total
                }
            }
        }
        timeObserverToken = token
    }

    private func removeTimeObserver() {
        guard let token = timeObserverToken else { return }
        player?.removeTimeObserver(token)
        timeObserverToken = nil
    }

    // MARK: - Playback End

    private func observePlaybackEnd(for item: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if self.isRepeatOn {
                    self._seek(to: 0)
                    self.player?.play()
                    self.isPlaying = true
                } else {
                    self._stop()
                }
            }
        }
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Deinit

    nonisolated deinit {
        // Time observer token is removed in stop() — this is a safety net only.
        // Accessing MainActor-isolated state from deinit is not safe in Swift 6;
        // rely on stop() being called before deallocation (onDisappear lifecycle).
    }
}
