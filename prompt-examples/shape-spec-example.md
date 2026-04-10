## Flow

1. do a plain /shape-spec
2. stop execution. Run /inject-standards
3. Inject the standards we need: module-composition and testing. No swiftui is necessary for this.
4. Claude you tell you that you can continue with the shape spec. Using prompt below:

## Prompt

What we're building: Task 2 — Network Layer

This is the foundation networking infrastructure for our app. Note that is implemented as a separate Swift Package - TuneAPI

 It must include:

- A protocol-based HTTP client abstraction (HTTPClient protocol) or ANY OTHER name you may see fit.
- A concrete URLSessionHTTPClient that conforms to the protocol - using async/await
- An iTunes Search API client that depends on the HTTPClient protocol (not URLSession directly)
- Request/Response models for the iTunes Search API
- Paginated search support using limit/offset parameters
- A typed error enum for network failures (connectivity, invalidData, server errors)
- JSON → domain model mapping at the network boundary
- Full test coverage: HTTPClient spy for testing the API client without network, response mapping tests, error handling tests
- Testing URLSessionHTTPClient: Use URLProtocolStub. a testing example implementation (legacy XCTest will be added below as reference)
- No other module or 3rd party import.

--- URLProtocolStub Example

final class URLSessionHTTPClientTests: XCTestCase {
    
    // MARK: - SetUp & TearDown
    
    override func setUp() async throws {
        try await super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() async throws {
        URLProtocolStub.stopInterceptingRequests()
        try await super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_getFromURL_performsGETRequestWithURL() async {
        let url = anyURL()
        URLProtocolStub.stub(data: nil, response: nil, error: AnyError())
        
        var observedRequest: URLRequest?
        
        URLProtocolStub.captureRequest { request in
            observedRequest = request
        }
        
        let sut = makeSUT()
        
        let _ = try? await sut.getData(from: url)
        
        XCTAssertNotNil(observedRequest)
        XCTAssertEqual(observedRequest?.url, url)
        XCTAssertEqual(observedRequest?.httpMethod, "GET")
    }
    
    // MARK: Error Cases
    
    func test_getFromURL_onRequestError_fails() async {
        // Needs to be NSError
        let expectedError = NSError(domain: "failsOnRequestError", code: 13)
        let url = anyURL()
     
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        let sut = makeSUT()
        
        await assertFailsWithNSError(expectedError) {
            _ = try await sut.getData(from: url)
        }
    }
}

private class URLProtocolStub: URLProtocol {
    // MARK: Properties and Helpers
    
    private static var stub: Stub?
    
    private static var captureRequest: ((URLRequest) -> Void)?
    
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
    
    static func captureRequest(observer: @escaping (URLRequest) -> Void) {
        captureRequest = observer
    }
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub(data: data, response: response, error: error)
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
        captureRequest = nil
    }
    
    // MARK: - URLProtocol
    
    override class func canInit(with request: URLRequest) -> Bool {
        captureRequest?(request)
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let stub = URLProtocolStub.stub else {
            // XCTFail() was not being displayed correctly, better crash instead.
            // Missing client didfinishloading
            fatalError("Test needs a stubbed response")
        }
        
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() { }
}

