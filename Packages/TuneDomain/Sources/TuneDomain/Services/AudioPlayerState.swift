import Foundation

public struct AudioPlayerState: Sendable {
    public let isPlaying: Bool
    public let isReadyToPlay: Bool
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    public let progress: Double

    public init(
        isPlaying: Bool,
        isReadyToPlay: Bool,
        currentTime: TimeInterval,
        duration: TimeInterval,
        progress: Double
    ) {
        self.isPlaying = isPlaying
        self.isReadyToPlay = isReadyToPlay
        self.currentTime = currentTime
        self.duration = duration
        self.progress = progress
    }

    public static let idle = AudioPlayerState(
        isPlaying: false,
        isReadyToPlay: false,
        currentTime: 0,
        duration: 0,
        progress: 0
    )
}
