import Foundation
import TuneDomain

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
