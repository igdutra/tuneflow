//
//  EventTracker.swift
//  TuneDomain
//
//  Created by Ivo on 13/04/26.
//

import Foundation

// Note: for now, lets leave the Tracker conforming to AnyObject but in theory that is a leaky abstraction due to the [weak self] need for InMemoryAnalyticsTracker
// This could be solved using a Proxy pattern that weakify all calls to the real class implementation.
public protocol EventTracker: AnyObject {
    func track(_ event: any TuneEvent)
}
