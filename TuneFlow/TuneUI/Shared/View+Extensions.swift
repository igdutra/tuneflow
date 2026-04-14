//
//  View+Extensions.swift
//  TuneFlow
//
//  Created by Ivo on 13/04/26.
//

import Foundation
import SwiftUI

// Note: Use code as documentation: create functions that act as documentation instead of comments.
public extension View {
    /// Expands hit-testing to the view's full bounds.
    /// Especially useful for views whose visual content is smaller than their layout frame (e.g., icons, custom shapes).
    func expandTappableArea() -> some View {
        self.contentShape(Rectangle())
    }
}
        
