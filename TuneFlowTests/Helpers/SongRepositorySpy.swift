import Foundation
import TuneDomain

final class SongRepositorySpy: SongRepository, @unchecked Sendable {
    private(set) var searchCallCount = 0
    private(set) var searchCalledWithQuery: String?
    private(set) var searchCalledWithLimit: Int?
    private(set) var searchCalledWithOffset: Int?

    private var stubbedSearchResult: Result<[Song], Error> = .success([])

    func search(query: String, limit: Int, offset: Int) async throws -> [Song] {
        searchCallCount += 1
        searchCalledWithQuery = query
        searchCalledWithLimit = limit
        searchCalledWithOffset = offset
        return try stubbedSearchResult.get()
    }

    func stub(result: [Song]) {
        stubbedSearchResult = .success(result)
    }

    func stub(error: Error) {
        stubbedSearchResult = .failure(error)
    }
}
