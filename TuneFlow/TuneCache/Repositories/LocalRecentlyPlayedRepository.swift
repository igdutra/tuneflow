import Foundation
import TuneDomain

final class LocalRecentlyPlayedRepository: RecentlyPlayedRepository {
    private let store: any RecentlyPlayedStore

    init(store: any RecentlyPlayedStore) {
        self.store = store
    }

    func save(_ song: Song) async throws {
        try await store.insert(song)
    }

    func loadRecent(limit: Int) async throws -> [Song] {
        let songs = try await store.retrieveAll()
        return Array(songs.prefix(limit))
    }
}
