import Testing
import Foundation
import SwiftData
import TuneDomain
@testable import TuneFlow

struct LocalRecentlyPlayedRepositoryTests {

    // MARK: - save

    @Test("save delegates to store insert")
    func save_delegatesToStoreInsert() async throws {
        let (sut, spy, _) = makeSUT()

        try await sut.save(.fixture())

        #expect(spy.insertCallCount == 1)
    }

    @Test("save passes correct song to store")
    func save_passesCorrectSong() async throws {
        let (sut, spy, _) = makeSUT()
        let song = Song.fixture(id: 42, trackName: "Thriller")

        try await sut.save(song)

        #expect(spy.insertCalledWithSong == song)
    }

    @Test("save on store error throws error")
    func save_onStoreError_throwsError() async throws {
        let (sut, spy, _) = makeSUT()
        spy.stubInsert(error: anyError())

        await #expect(throws: (any Error).self) {
            try await sut.save(.fixture())
        }
    }

    // MARK: - loadRecent

    @Test("loadRecent delegates to store retrieveAll")
    func loadRecent_delegatesToStoreRetrieveAll() async throws {
        let (sut, spy, _) = makeSUT()

        _ = try await sut.loadRecent(limit: 5)

        #expect(spy.retrieveAllCallCount == 1)
    }

    @Test("loadRecent maps stored songs back to domain songs")
    func loadRecent_mapsStoredSongsBackToDomainSongs() async throws {
        let (sut, spy, container) = makeSUT()
        let storedSongs = makeStoredSongs(ids: [1, 2], container: container)
        spy.stub(result: storedSongs)

        let result = try await sut.loadRecent(limit: 10)

        #expect(result.count == 2)
        #expect(result.map(\.id) == [1, 2])
    }

    @Test("loadRecent respects limit")
    func loadRecent_respectsLimit() async throws {
        let (sut, spy, container) = makeSUT()
        let storedSongs = makeStoredSongs(ids: [1, 2, 3, 4, 5], container: container)
        spy.stub(result: storedSongs)

        let result = try await sut.loadRecent(limit: 3)

        #expect(result.count == 3)
    }

    @Test("loadRecent on store error throws error")
    func loadRecent_onStoreError_throwsError() async throws {
        let (sut, spy, _) = makeSUT()
        spy.stub(error: anyError())

        await #expect(throws: (any Error).self) {
            _ = try await sut.loadRecent(limit: 5)
        }
    }
}

// MARK: - Helpers

private extension LocalRecentlyPlayedRepositoryTests {
    typealias SUTBundle = (sut: LocalRecentlyPlayedRepository, spy: RecentlyPlayedStoreSpy, container: ModelContainer)

    func makeSUT() -> SUTBundle {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: StoredSong.self, StoredPlayHistory.self, configurations: config)
        let spy = RecentlyPlayedStoreSpy()
        let sut = LocalRecentlyPlayedRepository(store: spy)
        return (sut, spy, container)
    }

    func makeStoredSongs(ids: [Int], container: ModelContainer) -> [StoredSong] {
        let context = ModelContext(container)
        return ids.map { id in
            let song = StoredSong(
                id: id,
                title: "Track \(id)",
                artist: "Artist",
                albumName: "Album",
                url: URL(string: "https://preview.com/\(id).m4a")!,
                artworkUrl: URL(string: "https://artwork.com/\(id).jpg")!,
                lastPlayedAt: Date()
            )
            context.insert(song)
            return song
        }
    }

    func anyError() -> Error {
        NSError(domain: "test", code: 0)
    }
}
