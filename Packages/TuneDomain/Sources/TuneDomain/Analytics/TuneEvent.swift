//
//  TuneEvent.swift
//  TuneDomain
//
//  Created by Ivo on 13/04/26.
//

import Foundation

// Protocol-based analytics keeps events decentralized.
// Each screen owns its event namespace as a struct with static factories,
// avoiding a single monolithic enum that grows unbounded and causes
// name collisions across unrelated features.
public protocol TuneEvent {
    var name: String { get }
    var parameters: [String: String] { get }
}
