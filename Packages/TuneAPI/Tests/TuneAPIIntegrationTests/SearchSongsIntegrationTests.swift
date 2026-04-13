import Foundation
import Testing
import TuneAPI
import TuneDomain

@Suite("TuneAPI Integration Tests")
struct SearchSongsIntegrationTests {

    @Test("search returns results for Jack Johnson")
    func search_withJackJohnsonQuery_returnsResults() async throws {
        let sut = makeSUT()

        let results = try await sut.search(query: "Jack Johnson", limit: 5, offset: 0)

        #expect(results.isEmpty == false)
        #expect(results.count <= 5)
    }

    @Test("fetchAlbum returns Discovery by Daft Punk")
    func fetchAlbum_withDaftPunkDiscovery_returnsAlbum() async throws {
        let sut = makeSUT()

        let album = try await sut.fetchAlbum(collectionId: 697194953)

        #expect(album.title == "Discovery")
        #expect(album.artistName == "Daft Punk")
        #expect(album.tracks.isEmpty == false)
    }

    // MARK: - Helpers

    private func makeSUT() -> RemoteSongRepository {
        let baseURL = URL(string: "https://itunes.apple.com/search")!
        let lookupBaseURL = URL(string: "https://itunes.apple.com/lookup")!
        let logger = NoOpStubLogger()
        return RemoteSongRepository(client: URLSessionHTTPClient(), baseURL: baseURL, lookupBaseURL: lookupBaseURL, logger: logger)
    }
}
