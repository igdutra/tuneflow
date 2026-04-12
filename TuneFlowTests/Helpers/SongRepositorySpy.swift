import Foundation
import TuneDomain

final class SongRepositorySpy: SongRepository, @unchecked Sendable {
    private(set) var searchCallCount = 0
    private(set) var searchCalledWithQuery: String?
    private(set) var searchCalledWithLimit: Int?
    private(set) var searchCalledWithOffset: Int?
    private(set) var fetchAlbumCallCount = 0
    private(set) var fetchAlbumCalledWithCollectionId: Int?

    private var stubbedSearchResult: Result<[Song], Error> = .success([])
    private var stubbedAlbumResult: Result<Album, Error> = .success(Album(
        id: 0, title: "", artistName: "", artworkURL: URL(string: "https://example.com")!, tracks: []
    ))

    func search(query: String, limit: Int, offset: Int) async throws -> [Song] {
        searchCallCount += 1
        searchCalledWithQuery = query
        searchCalledWithLimit = limit
        searchCalledWithOffset = offset
        return try stubbedSearchResult.get()
    }

    func fetchAlbum(collectionId: Int) async throws -> Album {
        fetchAlbumCallCount += 1
        fetchAlbumCalledWithCollectionId = collectionId
        return try stubbedAlbumResult.get()
    }

    func stub(result: [Song]) {
        stubbedSearchResult = .success(result)
    }

    func stub(error: Error) {
        stubbedSearchResult = .failure(error)
    }

    func stubAlbum(result: Album) {
        stubbedAlbumResult = .success(result)
    }

    func stubAlbum(error: Error) {
        stubbedAlbumResult = .failure(error)
    }
}
