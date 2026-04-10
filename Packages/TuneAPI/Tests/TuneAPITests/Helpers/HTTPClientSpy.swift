import Foundation
@testable import TuneAPI

final class HTTPClientSpy: HTTPClient, @unchecked Sendable {
    private(set) var requestedURLs: [URL] = []

    private var stubbedResult: Result<(Data, HTTPURLResponse), Error> = .failure(
        NSError(domain: "test", code: 0)
    )

    func stub(data: Data, response: HTTPURLResponse) {
        stubbedResult = .success((data, response))
    }

    func stub(error: Error) {
        stubbedResult = .failure(error)
    }

    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURLs.append(url)
        return try stubbedResult.get()
    }
}
