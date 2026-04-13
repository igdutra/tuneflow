//
//  InMemoryAnalyticsTracker.swift
//  TuneFlow
//
//  Created by Ivo on 13/04/26.
//

import Foundation
import TuneDomain

/// Stores analytics events in memory for the current app session.
///
/// Why an in-memory implementation:
/// - it keeps the analytics layer simple and dependency-free
/// - it allows event capture during development, previews, and tests
/// - it demonstrates that analytics emission is decoupled from any specific backend
///
/// Because all call sites depend on `EventTracker`, this implementation can be
/// replaced at the composition root by a real provider-backed tracker later
/// (for example: Amplitude, Firebase, Mixpanel, or a custom analytics service)
/// without changing feature code.
final class InMemoryAnalyticsTracker: EventTracker {
    private(set) var trackedEvents: [any TuneEvent] = []

    func track(_ event: any TuneEvent) {
        trackedEvents.append(event)
        print("[Analytics] \(event.name) \(event.parameters)")
    }

    func clear() {
        trackedEvents.removeAll()
    }

    var lastTrackedEvent: (any TuneEvent)? {
        trackedEvents.last
    }

    var trackedEventsCount: Int {
        trackedEvents.count
    }
}
