import Testing
import Foundation
import TuneDomain
@testable import TuneFlow

struct LocalRecentlyPlayedRepositoryTests {

    // MARK: - save

    @Test("save delegates to store insert")
    func save_delegatesToStoreInsert() async throws {
        let (sut, spy) = makeSUT()

        try await sut.save(.fixture())

        #expect(spy.insertCallCount == 1)
    }

    @Test("save passes correct song to store")
    func save_passesCorrectSong() async throws {
        let (sut, spy) = makeSUT()
        let song = Song.fixture(id: 42, trackName: "Thriller")

        try await sut.save(song)

        #expect(spy.insertCalledWithSong == song)
    }

    @Test("save on store error throws error")
    func save_onStoreError_throwsError() async throws {
        let (sut, spy) = makeSUT()
        spy.stubInsert(error: anyError())

        await #expect(throws: (any Error).self) {
            try await sut.save(.fixture())
        }
    }

    // MARK: - loadRecent

    @Test("loadRecent delegates to store retrieveAll")
    func loadRecent_delegatesToStoreRetrieveAll() async throws {
        let (sut, spy) = makeSUT()

        _ = try await sut.loadRecent(limit: 5)

        #expect(spy.retrieveAllCallCount == 1)
    }

    @Test("loadRecent maps stored songs back to domain songs")
    func loadRecent_mapsStoredSongsBackToDomainSongs() async throws {
        let (sut, spy) = makeSUT()
        spy.stub(result: makeSongs(ids: [1, 2]))

        let result = try await sut.loadRecent(limit: 10)

        #expect(result.count == 2)
        #expect(result.map(\.id) == [1, 2])
    }

    @Test("loadRecent respects limit")
    func loadRecent_respectsLimit() async throws {
        let (sut, spy) = makeSUT()
        spy.stub(result: makeSongs(ids: [1, 2, 3, 4, 5]))

        let result = try await sut.loadRecent(limit: 3)

        #expect(result.count == 3)
    }

    @Test("loadRecent on store error throws error")
    func loadRecent_onStoreError_throwsError() async throws {
        let (sut, spy) = makeSUT()
        spy.stub(error: anyError())

        await #expect(throws: (any Error).self) {
            _ = try await sut.loadRecent(limit: 5)
        }
    }
}

// MARK: - Helpers

private extension LocalRecentlyPlayedRepositoryTests {
    typealias SUTBundle = (sut: LocalRecentlyPlayedRepository, spy: RecentlyPlayedStoreSpy)

    func makeSUT() -> SUTBundle {
        let spy = RecentlyPlayedStoreSpy()
        let sut = LocalRecentlyPlayedRepository(store: spy)
        return (sut, spy)
    }

    func makeSongs(ids: [Int]) -> [Song] {
        ids.map { Song.fixture(id: $0) }
    }

    func anyError() -> Error {
        NSError(domain: "test", code: 0)
    }
}
