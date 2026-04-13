import Foundation
import TuneDomain

final class NoOpStubLogger: LogHandling {
    func error(_ message: String) { }
}
