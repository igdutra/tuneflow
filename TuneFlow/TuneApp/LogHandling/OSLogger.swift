//
//  OSLogger.swift
//  TuneFlow
//
//  Created by Ivo on 13/04/26.
//

import Foundation
import TuneDomain
import OSLog


/// Concrete `AppLogging` implementation backed by Apple's `Logger` (`OSLog`).
///
/// Logs are emitted to the Apple unified logging system and can be inspected in:
/// - Xcode console
/// - Console.app on macOS
/// - Instruments / system diagnostics
///
/// Because feature code depends only on `AppLogging`, this implementation can be
/// replaced at the composition root by a production-grade remote logging solution
/// later (for example: Datadog, Sentry, Crashlytics, or a custom telemetry service)
/// without changing call sites.
struct OSLogger: LogHandling {
    private let logger: Logger

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.ivo.tuneFlow",
        category: String = "app"
    ) {
        self.logger = Logger(
            subsystem: subsystem,
            category: category
        )
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
