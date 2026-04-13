//
//  LogHandling.swift
//  TuneDomain
//
//  Created by Ivo on 13/04/26.
//

import Foundation

public protocol LogHandling: Sendable {
    func error(_ message: String)
    // TODO: Can have separate info, warning, methods etc.
}
