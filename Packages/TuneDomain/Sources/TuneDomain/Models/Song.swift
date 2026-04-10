import Foundation

public struct Song: Sendable, Equatable {
    public let id: Int
    public let trackName: String
    public let artistName: String
    public let albumName: String
    public let artworkURL: URL
    public let previewURL: URL?
    public let trackNumber: Int?

    public init(
        id: Int,
        trackName: String,
        artistName: String,
        albumName: String,
        artworkURL: URL,
        previewURL: URL?,
        trackNumber: Int?
    ) {
        self.id = id
        self.trackName = trackName
        self.artistName = artistName
        self.albumName = albumName
        self.artworkURL = artworkURL
        self.previewURL = previewURL
        self.trackNumber = trackNumber
    }
}
