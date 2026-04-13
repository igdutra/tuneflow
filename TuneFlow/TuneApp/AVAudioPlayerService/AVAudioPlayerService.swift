import AVFoundation
import TuneDomain

@MainActor
class AVAudioPlayerService: AudioPlayerService {

    // MARK: - AudioPlayerService

    private(set) var isPlaying: Bool = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var progress: Double = 0
    var onStateChange: (@MainActor @Sendable (AudioPlayerState) -> Void)?

    // MARK: - Internal

    private(set) var player: AVPlayer?
    var isRepeatOn: Bool = false

    // MARK: - Private

    private var timeObserverToken: Any?

    // MARK: - AudioPlayerService Methods

    func play(url: URL) {
        stop()
        configureAudioSession()
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        observeItemReady(item: item)
        newPlayer.play()
        isPlaying = true
        addPeriodicTimeObserver(to: newPlayer)
        observePlaybackEnd(for: item)
        publishState()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        publishState()
    }

    func resume() {
        player?.play()
        isPlaying = true
        publishState()
    }

    func stop() {
        removeTimeObserver()
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        progress = 0
        publishState()
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
        publishState()
    }

    // MARK: - Item Ready

    private func observeItemReady(item: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.timeJumpedNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.publishState() }
        }
        // Observe status via KVO — needed for isReadyToPlay
        Task { @MainActor in
            for await _ in NotificationCenter.default.notifications(
                named: AVPlayerItem.newAccessLogEntryNotification,
                object: item
            ) {
                self.publishState()
            }
        }
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
                self.publishState()
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
                    self.seek(to: 0)
                    self.player?.play()
                    self.isPlaying = true
                } else {
                    self.stop()
                }
                self.publishState()
            }
        }
    }

    // MARK: - State Publishing

    private func publishState() {
        let isReady = player?.currentItem?.status == .readyToPlay
        let state = AudioPlayerState(
            isPlaying: isPlaying,
            isReadyToPlay: isReady,
            currentTime: currentTime,
            duration: duration,
            progress: progress
        )
        onStateChange?(state)
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Deinit

    nonisolated deinit {
        // Time observer removed in stop() / onDisappear lifecycle.
    }
}
