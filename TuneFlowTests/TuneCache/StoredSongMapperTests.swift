import Testing
import Foundation
import TuneDomain
@testable import TuneFlow

struct StoredSongMapperTests {

    // MARK: - toStorage

    @Test("toStorage maps all fields correctly")
    func toStorage_mapsAllFieldsCorrectly() {
        let song = Song.fixture()

        let stored = StoredSongMapper.toStorage(from: song, cache: nil)

        #expect(stored.id == song.id)
        #expect(stored.title == song.trackName)
        #expect(stored.artist == song.artistName)
        #expect(stored.albumName == song.albumName)
        #expect(stored.artworkUrl == song.artworkURL)
        #expect(stored.url == song.previewURL)
        #expect(stored.cache == nil)
    }

    @Test("toStorage sets lastPlayedAt to approximately now")
    func toStorage_setsLastPlayedAtToApproximatelyNow() {
        let before = Date()
        let stored = StoredSongMapper.toStorage(from: .fixture(), cache: nil)
        let after = Date()

        #expect(stored.lastPlayedAt >= before)
        #expect(stored.lastPlayedAt <= after)
    }

    // MARK: - toDomain

    @Test("toDomain maps all fields correctly")
    func toDomain_mapsAllFieldsCorrectly() {
        let song = Song.fixture()
        let stored = StoredSongMapper.toStorage(from: song, cache: nil)

        let domain = StoredSongMapper.toDomain(from: stored)

        #expect(domain.id == song.id)
        #expect(domain.trackName == song.trackName)
        #expect(domain.artistName == song.artistName)
        #expect(domain.albumName == song.albumName)
        #expect(domain.artworkURL == song.artworkURL)
        #expect(domain.previewURL == song.previewURL)
    }
}
