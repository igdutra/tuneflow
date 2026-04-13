//
//  TuneEventTracker.swift
//  TuneDomain
//
//  Created by Ivo on 13/04/26.
//

import Foundation

public protocol TuneEventTracker {
    func track(_ event: any TuneEvent)
}
