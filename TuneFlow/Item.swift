//
//  Item.swift
//  TuneFlow
//
//  Created by Ivo on 09/04/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
