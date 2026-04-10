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

    // MARK: - Helpers

    private func makeSUT() -> RemoteSongRepository {
        let baseURL = URL(string: "https://itunes.apple.com/search")!
        return RemoteSongRepository(client: URLSessionHTTPClient(), baseURL: baseURL)
    }
}
