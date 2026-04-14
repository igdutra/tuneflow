import Foundation
import SwiftData

@Model
final class StoredSong {
    @Attribute(.unique) var id: Int
    var title: String
    var artist: String
    var albumName: String?
    var collectionId: Int?
    var url: URL
    var artworkUrl: URL?
    var lastPlayedAt: Date
    var cache: StoredPlayHistory?

    init(
        id: Int,
        title: String,
        artist: String,
        albumName: String?,
        collectionId: Int?,
        url: URL,
        artworkUrl: URL?,
        lastPlayedAt: Date
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumName = albumName
        self.collectionId = collectionId
        self.url = url
        self.artworkUrl = artworkUrl
        self.lastPlayedAt = lastPlayedAt
    }
}
