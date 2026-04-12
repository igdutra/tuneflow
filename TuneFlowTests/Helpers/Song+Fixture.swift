import Foundation
import TuneDomain

extension Song {
    static func fixture(
        id: Int = 1,
        trackName: String = "Track Name",
        artistName: String = "Artist Name",
        albumName: String = "Album Name",
        collectionId: Int = 100,
        artworkURL: URL = URL(string: "https://artwork.com/100x100.jpg")!,
        previewURL: URL? = URL(string: "https://preview.com/song.m4a"),
        trackNumber: Int? = 1
    ) -> Song {
        Song(
            id: id,
            trackName: trackName,
            artistName: artistName,
            albumName: albumName,
            collectionId: collectionId,
            artworkURL: artworkURL,
            previewURL: previewURL,
            trackNumber: trackNumber
        )
    }

    static func fixtures(count: Int, startingId: Int = 1) -> [Song] {
        (0..<count).map { i in
            fixture(id: startingId + i, trackName: "Track \(startingId + i)")
        }
    }
}
