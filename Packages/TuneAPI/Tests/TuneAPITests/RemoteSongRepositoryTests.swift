import Testing
import Foundation
import TuneDomain
@testable import TuneAPI

struct RemoteSongRepositoryTests {

    // MARK: - Initialization

    @Test func init_doesNotRequestData() {
        let (_, clientSpy, _) = makeSUT()

        #expect(clientSpy.requestedURLs.isEmpty)
    }

    // MARK: - URL Construction

    @Test func search_buildsCorrectURL() async throws {
        let baseURL = URL(string: "https://itunes.apple.com/search")!
        let (sut, clientSpy, _) = makeSUT(baseURL: baseURL)
        clientSpy.stub(data: emptyEnvelopeData(), response: anyHTTPURLResponse(statusCode: 200))

        _ = try await sut.search(query: "Beatles", limit: 20, offset: 0)

        let requestedURL = try #require(clientSpy.requestedURLs.first)
        let components = try #require(URLComponents(url: requestedURL, resolvingAgainstBaseURL: false))
        let items = try #require(components.queryItems)

        #expect(items.first(where: { $0.name == "term" })?.value == "Beatles")
        #expect(items.first(where: { $0.name == "media" })?.value == "music")
        #expect(items.first(where: { $0.name == "limit" })?.value == "20")
        #expect(items.first(where: { $0.name == "offset" })?.value == "0")
    }

    @Test func search_withPaginationOffset_buildsCorrectOffsetParameter() async throws {
        let (sut, clientSpy, _) = makeSUT()
        clientSpy.stub(data: emptyEnvelopeData(), response: anyHTTPURLResponse(statusCode: 200))

        _ = try await sut.search(query: "Beatles", limit: 20, offset: 40)

        let requestedURL = try #require(clientSpy.requestedURLs.first)
        let components = try #require(URLComponents(url: requestedURL, resolvingAgainstBaseURL: false))
        let items = try #require(components.queryItems)
        #expect(items.first(where: { $0.name == "offset" })?.value == "40")
    }

    // MARK: - Success

    @Test func search_onValidResponse_deliversMappedSongs() async throws {
        let (sut, clientSpy, _) = makeSUT()
        let expectedSong = Song.fixture()
        let songData = makeEnvelopeData(songs: [makeSongJSON(from: expectedSong)])
        clientSpy.stub(data: songData, response: anyHTTPURLResponse(statusCode: 200))

        let result = try await sut.search(query: "Beatles", limit: 20, offset: 0)

        #expect(result == [expectedSong])
    }

    @Test func search_onEmptyResults_deliversEmptyArray() async throws {
        let (sut, clientSpy, _) = makeSUT()
        clientSpy.stub(data: emptyEnvelopeData(), response: anyHTTPURLResponse(statusCode: 200))

        let result = try await sut.search(query: "noresults", limit: 20, offset: 0)

        #expect(result.isEmpty)
    }

    @Test func search_onValidResponse_handlesOptionalFields() async throws {
        let (sut, clientSpy, _) = makeSUT()
        let songWithoutOptionals = Song.fixture(previewURL: nil, trackNumber: nil)
        let json = makeSongJSON(from: songWithoutOptionals, includePreviewURL: false, includeTrackNumber: false)
        clientSpy.stub(data: makeEnvelopeData(songs: [json]), response: anyHTTPURLResponse(statusCode: 200))

        let result = try await sut.search(query: "Beatles", limit: 20, offset: 0)

        let song = try #require(result.first)
        #expect(song.previewURL == nil)
        #expect(song.trackNumber == nil)
    }

    // MARK: - Failures

    @Test func search_onConnectivityError_throwsConnectivityError() async throws {
        let (sut, clientSpy, _) = makeSUT()
        clientSpy.stub(error: RemoteSongRepositoryError.connectivity)

        await #expect(throws: RemoteSongRepositoryError.connectivity) {
            _ = try await sut.search(query: "Beatles", limit: 20, offset: 0)
        }
    }

    @Test(arguments: [199, 201, 300, 400, 500])
    func search_onNon200HTTPResponse_throwsInvalidData(statusCode: Int) async throws {
        let (sut, clientSpy, _) = makeSUT()
        clientSpy.stub(data: emptyEnvelopeData(), response: anyHTTPURLResponse(statusCode: statusCode))

        await #expect(throws: RemoteSongRepositoryError.invalidData) {
            _ = try await sut.search(query: "Beatles", limit: 20, offset: 0)
        }
    }

    @Test func search_onMalformedJSON_throwsInvalidData() async throws {
        let (sut, clientSpy, _) = makeSUT()
        clientSpy.stub(data: Data("not json".utf8), response: anyHTTPURLResponse(statusCode: 200))

        await #expect(throws: RemoteSongRepositoryError.invalidData) {
            _ = try await sut.search(query: "Beatles", limit: 20, offset: 0)
        }
    }

    @Test func search_onError_logsErrorMessage() async throws {
        let (sut, clientSpy, logSpy) = makeSUT()
        clientSpy.stub(error: RemoteSongRepositoryError.connectivity)

        await #expect(throws: RemoteSongRepositoryError.connectivity) {
            _ = try await sut.search(query: "Beatles", limit: 20, offset: 0)
        }

        #expect(logSpy.errorMessages.count == 1)
        #expect(logSpy.errorMessages.first?.contains("Search failed") == true)
    }

    // MARK: - fetchAlbum URL Construction

    @Test func fetchAlbum_buildsCorrectURL() async throws {
        let lookupURL = URL(string: "https://itunes.apple.com/lookup")!
        let (sut, clientSpy, _) = makeSUT(lookupBaseURL: lookupURL)
        clientSpy.stub(data: emptyLookupData(), response: anyHTTPURLResponse(statusCode: 200))

        _ = try? await sut.fetchAlbum(collectionId: 123)

        let requestedURL = try #require(clientSpy.requestedURLs.first)
        let components = try #require(URLComponents(url: requestedURL, resolvingAgainstBaseURL: false))
        let items = try #require(components.queryItems)

        #expect(items.first(where: { $0.name == "id" })?.value == "123")
        #expect(items.first(where: { $0.name == "entity" })?.value == "song")
    }

    // MARK: - fetchAlbum Failures

    @Test func fetchAlbum_onConnectivityError_throwsConnectivityError() async throws {
        let (sut, clientSpy, _) = makeSUT()
        clientSpy.stub(error: RemoteSongRepositoryError.connectivity)

        await #expect(throws: RemoteSongRepositoryError.connectivity) {
            _ = try await sut.fetchAlbum(collectionId: 123)
        }
    }

    @Test(arguments: [199, 201, 300, 400, 500])
    func fetchAlbum_onNon200HTTPResponse_throwsInvalidData(statusCode: Int) async throws {
        let (sut, clientSpy, _) = makeSUT()
        clientSpy.stub(data: emptyLookupData(), response: anyHTTPURLResponse(statusCode: statusCode))

        await #expect(throws: RemoteSongRepositoryError.invalidData) {
            _ = try await sut.fetchAlbum(collectionId: 123)
        }
    }
}

// MARK: - Helpers

private extension RemoteSongRepositoryTests {
    typealias SUTBundle = (sut: RemoteSongRepository, clientSpy: HTTPClientSpy, logSpy: LogHandlingSpy)

    func makeSUT(
        baseURL: URL = URL(string: "https://itunes.apple.com/search")!,
        lookupBaseURL: URL = URL(string: "https://itunes.apple.com/lookup")!,
        source: SourceLocation = #_sourceLocation
    ) -> SUTBundle {
        let clientSpy = HTTPClientSpy()
        let logSpy = LogHandlingSpy()
        let sut = RemoteSongRepository(client: clientSpy, baseURL: baseURL, lookupBaseURL: lookupBaseURL, logger: logSpy)
        _ = source
        return (sut, clientSpy, logSpy)
    }

    func anyHTTPURLResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://itunes.apple.com/search")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    func emptyEnvelopeData() -> Data {
        Data("""
        {"resultCount":0,"results":[]}
        """.utf8)
    }

    func emptyLookupData() -> Data {
        Data("""
        {"resultCount":0,"results":[]}
        """.utf8)
    }

    func makeEnvelopeData(songs: [[String: Any]]) -> Data {
        let envelope: [String: Any] = [
            "resultCount": songs.count,
            "results": songs
        ]
        return try! JSONSerialization.data(withJSONObject: envelope)
    }

    func makeSongJSON(
        from song: Song,
        includePreviewURL: Bool = true,
        includeTrackNumber: Bool = true
    ) -> [String: Any] {
        var json: [String: Any] = [
            "trackId": song.id,
            "trackName": song.trackName,
            "artistName": song.artistName,
            "collectionName": song.albumName,
            "collectionId": song.collectionId,
            "artworkUrl100": song.artworkURL.absoluteString,
        ]
        if includePreviewURL, let previewURL = song.previewURL {
            json["previewUrl"] = previewURL.absoluteString
        }
        if includeTrackNumber, let trackNumber = song.trackNumber {
            json["trackNumber"] = trackNumber
        }
        return json
    }
}
