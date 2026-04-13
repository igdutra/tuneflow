import Foundation

public protocol AudioPlayerService: AnyObject, Sendable {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var progress: Double { get }

    /// Called on the main actor whenever playback state changes.
    /// The VM wires this in `onAppear` to copy service state into stored observable properties.
    var onStateChange: (@MainActor @Sendable (AudioPlayerState) -> Void)? { get set }

    func play(url: URL)
    func pause()
    func resume()
    func stop()
    func seek(to time: TimeInterval)
}
