//
//  OSLogger.swift
//  TuneFlow
//
//  Created by Ivo on 13/04/26.
//

import Foundation
import TuneDomain
import OSLog

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
