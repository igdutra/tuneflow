//
//  EventTracker.swift
//  TuneDomain
//
//  Created by Ivo on 13/04/26.
//

import Foundation

public protocol EventTracker: AnyObject {
    func track(_ event: any TuneEvent)
}
