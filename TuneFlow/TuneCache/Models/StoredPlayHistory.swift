import Foundation
import SwiftData

@Model
final class StoredPlayHistory {
    @Relationship(deleteRule: .cascade, inverse: \StoredSong.cache)
    var songs: [StoredSong] = []
    var lastUpdatedAt: Date

    init(lastUpdatedAt: Date = Date()) {
        self.lastUpdatedAt = lastUpdatedAt
    }
}
