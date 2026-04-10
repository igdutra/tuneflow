import Testing
import Foundation
@testable import TuneAPI

/// Test notes:
/// URLProtocolStub lets these infrastructure tests exercise the real URLSession-based client
/// without performing actual HTTP requests.
/// URLProtocolStub uses global URLProtocol registration — tests must run serially.
/// Why final class vs struct? With class + Swift Test we can get the init + deinit methods, reassuring clean state execution since we are dealing with possilbe side-effects (URLProtocolStub is global scope) between tests.
@Suite(.serialized)
final class URLSessionHTTPClientTests {
    init() {
        URLProtocolStub.startInterceptingRequests()
    }

    deinit {
        URLProtocolStub.stopInterceptingRequests()
    }

    @Test func get_performsGETRequestWithURL() async throws {
        let url = anyURL()
        let sut = makeSUT()
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
        let sut = makeSUT()
        let expectedData = Data("any data".utf8)
        let expectedResponse = anyHTTPURLResponse(url: url, statusCode: 200)
        URLProtocolStub.stub(data: expectedData, response: expectedResponse, error: nil)

        let (receivedData, receivedResponse) = try await sut.get(from: url)

        #expect(receivedData == expectedData)
        #expect(receivedResponse.statusCode == expectedResponse.statusCode)
        #expect(receivedResponse.url == expectedResponse.url)
    }

    @Test func get_onConnectivityError_throwsConnectivityError() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: nil, response: nil, error: anyNSError())

        await #expect(throws: RemoteSongRepositoryError.connectivity) {
            _ = try await sut.get(from: anyURL())
        }
    }

    @Test func get_onNonHTTPResponse_throwsConnectivityError() async throws {
        let url = anyURL()
        let sut = makeSUT()
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        URLProtocolStub.stub(data: Data(), response: response, error: nil)

        await #expect(throws: RemoteSongRepositoryError.connectivity) {
            _ = try await sut.get(from: url)
        }
    }
}

// MARK: - Helpers

private extension URLSessionHTTPClientTests {
    func makeSUT(source: SourceLocation = #_sourceLocation) -> URLSessionHTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let sut = URLSessionHTTPClient(session: session)
        _ = source
        return sut
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
