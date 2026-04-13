import Foundation
import TuneDomain

final class LogHandlingSpy: LogHandling, @unchecked Sendable {
    private(set) var errorMessages: [String] = []

    nonisolated func error(_ message: String) {
        // Cast to get access - acceptable for test spies
        let mutableSelf = Unmanaged.passUnretained(self).takeUnretainedValue()
        mutableSelf.errorMessages.append(message)
    }
}
