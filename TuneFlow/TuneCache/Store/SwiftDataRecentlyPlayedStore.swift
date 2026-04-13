import Foundation
import SwiftData
import TuneDomain

@ModelActor
final actor SwiftDataRecentlyPlayedStore: RecentlyPlayedStore {

    func insert(_ song: Song) async throws {
        let history = try fetchOrCreateHistory()

        let songID = song.id
        let descriptor = FetchDescriptor<StoredSong>(
            predicate: #Predicate<StoredSong> { $0.id == songID }
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

    // TODO: Analyse Swift6 Errors
    func retrieveAll() throws -> [StoredSong] {
        // We sort in the FetchDescriptor so the persistent store (SwiftData/Core Data + SQLite) does the work,
        // which is more efficient and guarantees deterministic results instead of fetching unsorted data and sorting in memory.
        // SwiftData fetches are not ordered by default unless you explicitly provide sort descriptors; Core Data's ordered support
        // applies to ordered relationships (e.g. NSOrderedSet), not to general top-level fetch results like this one.
        let descriptor = FetchDescriptor<StoredSong>(
            sortBy: [SortDescriptor(\.lastPlayedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
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

