import Foundation
import TuneDomain
@testable import TuneFlow

final class RecentlyPlayedStoreSpy: RecentlyPlayedStore, @unchecked Sendable {
    private(set) var insertCallCount = 0
    private(set) var insertCalledWithSong: Song?
    private(set) var retrieveAllCallCount = 0

    private var stubbedInsertError: Error?
    private var stubbedRetrieveAllResult: Result<[StoredSong], Error> = .success([])

    func insert(_ song: Song) async throws {
        insertCallCount += 1
        insertCalledWithSong = song
        if let error = stubbedInsertError { throw error }
    }

    func retrieveAll() async throws -> [StoredSong] {
        retrieveAllCallCount += 1
        return try stubbedRetrieveAllResult.get()
    }

    func stubInsert(error: Error) {
        stubbedInsertError = error
    }

    func stub(result: [StoredSong]) {
        stubbedRetrieveAllResult = .success(result)
    }

    func stub(error: Error) {
        stubbedRetrieveAllResult = .failure(error)
    }
}
