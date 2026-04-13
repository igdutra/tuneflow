import Foundation
import TuneDomain

final class RecentlyPlayedRepositorySpy: RecentlyPlayedRepository, @unchecked Sendable {
    private(set) var saveCallCount = 0
    private(set) var saveCalledWithSong: Song?
    var onSave: (@Sendable (Song) -> Void)?
    private(set) var loadRecentCallCount = 0
    private(set) var loadRecentCalledWithLimit: Int?

    private var stubbedSaveError: Error?
    private var stubbedLoadResult: Result<[Song], Error> = .success([])

    func save(_ song: Song) async throws {
        saveCallCount += 1
        saveCalledWithSong = song
        onSave?(song)
        if let error = stubbedSaveError { throw error }
    }

    func loadRecent(limit: Int) async throws -> [Song] {
        loadRecentCallCount += 1
        loadRecentCalledWithLimit = limit
        return try stubbedLoadResult.get()
    }

    func stubSave(error: Error) {
        stubbedSaveError = error
    }

    func stub(result: [Song]) {
        stubbedLoadResult = .success(result)
    }

    func stub(error: Error) {
        stubbedLoadResult = .failure(error)
    }
}
