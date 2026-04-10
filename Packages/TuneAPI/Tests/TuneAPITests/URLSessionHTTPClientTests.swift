import Testing
import Foundation
@testable import TuneAPI

// URLProtocolStub uses global URLProtocol registration — tests must run serially.
@Suite(.serialized)
struct URLSessionHTTPClientTests {
    @Test func get_performsGETRequestWithURL() async throws {
        let url = anyURL()
        let (sut, _) = makeSUT()
        let expectedResponse = anyHTTPURLResponse(url: url, statusCode: 200)
        URLProtocolStub.stub(data: Data(), response: expectedResponse, error: nil)

        var capturedRequest: URLRequest?
        URLProtocolStub.observeRequests { capturedRequest = $0 }

        _ = try await sut.get(from: url)

        #expect(capturedRequest?.url == url)
        #expect(capturedRequest?.httpMethod == "GET")
    }

    @Test func get_onSuccess_deliversDataAndResponse() async throws {
        let url = anyURL()
        let (sut, _) = makeSUT()
        let expectedData = Data("any data".utf8)
        let expectedResponse = anyHTTPURLResponse(url: url, statusCode: 200)
        URLProtocolStub.stub(data: expectedData, response: expectedResponse, error: nil)

        let (receivedData, receivedResponse) = try await sut.get(from: url)

        #expect(receivedData == expectedData)
        #expect(receivedResponse.statusCode == expectedResponse.statusCode)
        #expect(receivedResponse.url == expectedResponse.url)
    }

    @Test func get_onConnectivityError_throwsConnectivityError() async throws {
        let (sut, _) = makeSUT()
        URLProtocolStub.stub(data: nil, response: nil, error: anyNSError())

        await #expect(throws: RemoteSongRepositoryError.connectivity) {
            _ = try await sut.get(from: anyURL())
        }
    }
}

// MARK: - Helpers

private extension URLSessionHTTPClientTests {
    typealias SUTBundle = (sut: URLSessionHTTPClient, stub: URLProtocolStub.Type)

    func makeSUT(source: SourceLocation = #_sourceLocation) -> SUTBundle {
        URLProtocolStub.startInterceptingRequests()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let sut = URLSessionHTTPClient(session: session)
        _ = source
        // Teardown: stopInterceptingRequests called per-test via defer in each test would be ideal,
        // but since the suite is .serialized we stop in each test helper.
        return (sut, URLProtocolStub.self)
    }

    func anyURL() -> URL {
        URL(string: "https://any-url.com")!
    }

    func anyHTTPURLResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
    
    // TODO: Instead of using NSError, create struct AnyError: Swift.Error { }
    func anyNSError() -> NSError {
        NSError(domain: "test", code: 0)
    }
}
