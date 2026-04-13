import Foundation
import SwiftData
import TuneDomain

@ModelActor
final actor SwiftDataRecentlyPlayedStore: RecentlyPlayedStore {

    func insert(_ song: Song) async throws {
        let history = try fetchOrCreateHistory()

        let descriptor = FetchDescriptor<StoredSong>(
            predicate: #Predicate { $0.id == song.id }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.lastPlayedAt = Date()
        } else {
            let stored = StoredSongMapper.toStorage(from: song, cache: history)
            modelContext.insert(stored)
            history.songs.append(stored)
        }
        history.lastUpdatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func retrieveAll() async throws -> [StoredSong] {
        let descriptor = FetchDescriptor<StoredSong>()
        let all = try modelContext.fetch(descriptor)
        return all.sorted { $0.lastPlayedAt > $1.lastPlayedAt }
    }

    // MARK: - Private

    private func fetchOrCreateHistory() throws -> StoredPlayHistory {
        let descriptor = FetchDescriptor<StoredPlayHistory>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let history = StoredPlayHistory()
        modelContext.insert(history)
        return history
    }
}
