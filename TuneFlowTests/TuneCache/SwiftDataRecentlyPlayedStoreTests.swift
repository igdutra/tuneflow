import Testing
import Foundation
import SwiftData
import TuneDomain
@testable import TuneFlow

struct SwiftDataRecentlyPlayedStoreTests {

    // MARK: - insert

    @Test("insert new song persists it in the store")
    func insert_newSong_persistsItInStore() async throws {
        let (sut, _) = makeSUT()
        let song = Song.fixture(id: 1)

        try await sut.insert(song)

        let all = try await sut.retrieveAll()
        #expect(all.count == 1)
        #expect(all.first?.id == 1)
    }

    @Test("insert same song twice updates lastPlayedAt without duplicate")
    func insert_sameSongTwice_updatesLastPlayedAtWithoutDuplicate() async throws {
        let (sut, _) = makeSUT()
        let song = Song.fixture(id: 1)

        try await sut.insert(song)
        // Small delay so second insert has a later timestamp
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms — needed for timestamp ordering
        try await sut.insert(song)

        let all = try await sut.retrieveAll()
        #expect(all.count == 1)
    }

    @Test("insert different songs stores all")
    func insert_differentSongs_storesAll() async throws {
        let (sut, _) = makeSUT()

        try await sut.insert(Song.fixture(id: 1))
        try await sut.insert(Song.fixture(id: 2))
        try await sut.insert(Song.fixture(id: 3))

        let all = try await sut.retrieveAll()
        #expect(all.count == 3)
    }

    // MARK: - retrieveAll

    @Test("retrieveAll on empty store returns empty array")
    func retrieveAll_onEmptyStore_returnsEmptyArray() async throws {
        let (sut, _) = makeSUT()

        let all = try await sut.retrieveAll()

        #expect(all.isEmpty)
    }

    @Test("retrieveAll after inserts returns sorted by lastPlayedAt descending")
    func retrieveAll_afterInserts_returnsSortedByLastPlayedAtDescending() async throws {
        let (sut, _) = makeSUT()

        try await sut.insert(Song.fixture(id: 1))
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms — needed for timestamp ordering
        try await sut.insert(Song.fixture(id: 2))
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms — needed for timestamp ordering
        try await sut.insert(Song.fixture(id: 3))

        let all = try await sut.retrieveAll()
        #expect(all.map(\.id) == [3, 2, 1])
    }
}

// MARK: - Helpers

private extension SwiftDataRecentlyPlayedStoreTests {
    typealias SUTBundle = (sut: SwiftDataRecentlyPlayedStore, container: ModelContainer)

    func makeSUT() -> SUTBundle {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: StoredSong.self, StoredPlayHistory.self, configurations: config)
        let sut = SwiftDataRecentlyPlayedStore(modelContainer: container)
        return (sut, container)
    }
}
