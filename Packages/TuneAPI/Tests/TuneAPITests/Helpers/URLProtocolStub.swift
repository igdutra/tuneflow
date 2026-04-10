import Foundation

// URLProtocol registers globally, so tests using this stub must be serialized.
// See: URLSessionHTTPClientTests — marked .serialized for this reason.
final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _stub: Stub?
    nonisolated(unsafe) private static var _requestObserver: ((URLRequest) -> Void)?

    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        lock.withLock { _stub = Stub(data: data, response: response, error: error) }
    }

    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        lock.withLock { _requestObserver = observer }
    }

    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        lock.withLock {
            _stub = nil
            _requestObserver = nil
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (stub, observer) = URLProtocolStub.lock.withLock {
            (URLProtocolStub._stub, URLProtocolStub._requestObserver)
        }

        observer?(request)

        if let error = stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        if let response = stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
