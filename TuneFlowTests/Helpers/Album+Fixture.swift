import Foundation
import TuneDomain

extension Album {
    static func fixture(
        id: Int = 100,
        title: String = "Album Title",
        artistName: String = "Artist Name",
        artworkURL: URL = URL(string: "https://artwork.com/100x100.jpg")!,
        tracks: [Song] = [.fixture()]
    ) -> Album {
        Album(
            id: id,
            title: title,
            artistName: artistName,
            artworkURL: artworkURL,
            tracks: tracks
        )
    }
}
