import Foundation
import TuneDomain

enum StoredSongMapper {
    static func toStorage(from song: Song, cache: StoredPlayHistory?) -> StoredSong {
        StoredSong(
            id: song.id,
            title: song.trackName,
            artist: song.artistName,
            albumName: song.albumName,
            url: song.previewURL ?? song.artworkURL,
            artworkUrl: song.artworkURL,
            lastPlayedAt: Date()
        )
    }

    static func toDomain(from stored: StoredSong) -> Song {
        Song(
            id: stored.id,
            trackName: stored.title,
            artistName: stored.artist,
            albumName: stored.albumName,
            collectionId: 0,
            artworkURL: stored.artworkUrl ?? stored.url,
            previewURL: stored.url,
            trackNumber: nil
        )
    }
}
