import Foundation

public struct Album: Sendable, Equatable {
    public let id: Int
    public let title: String
    public let artistName: String
    public let artworkURL: URL
    public let tracks: [Song]

    public init(
        id: Int,
        title: String,
        artistName: String,
        artworkURL: URL,
        tracks: [Song]
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artworkURL = artworkURL
        self.tracks = tracks
    }
}
