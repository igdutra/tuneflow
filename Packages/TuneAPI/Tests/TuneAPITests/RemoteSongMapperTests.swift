import Testing
import Foundation
import TuneDomain
@testable import TuneAPI

struct RemoteSongMapperTests {

    @Test func map_on200_withValidJSON_deliversSongs() throws {
        let expectedSong = Song.fixture()
        let data = makeEnvelopeData(songs: [makeSongJSON(from: expectedSong)])
        let response = anyHTTPURLResponse(statusCode: 200)

        let result = try RemoteSongMapper.map(data, response)

        #expect(result == [expectedSong])
    }

    @Test func map_on200_withEmptyResults_deliversEmptyArray() throws {
        let data = Data("""
        {"resultCount":0,"results":[]}
        """.utf8)
        let response = anyHTTPURLResponse(statusCode: 200)

        let result = try RemoteSongMapper.map(data, response)

        #expect(result.isEmpty)
    }

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_onNon200Response_throwsInvalidData(statusCode: Int) throws {
        let data = Data("""
        {"resultCount":0,"results":[]}
        """.utf8)
        let response = anyHTTPURLResponse(statusCode: statusCode)

        #expect(throws: RemoteSongRepositoryError.invalidData) {
            try RemoteSongMapper.map(data, response)
        }
    }

    @Test func map_on200_withMalformedJSON_throwsInvalidData() throws {
        let response = anyHTTPURLResponse(statusCode: 200)

        #expect(throws: RemoteSongRepositoryError.invalidData) {
            try RemoteSongMapper.map(Data("invalid".utf8), response)
        }
    }

    @Test func map_on200_withOptionalFieldsAbsent_mapsNilFields() throws {
        let songWithoutOptionals = Song.fixture(previewURL: nil, trackNumber: nil)
        let json = makeSongJSON(from: songWithoutOptionals, includePreviewURL: false, includeTrackNumber: false)
        let data = makeEnvelopeData(songs: [json])
        let response = anyHTTPURLResponse(statusCode: 200)

        let result = try RemoteSongMapper.map(data, response)

        let song = try #require(result.first)
        #expect(song.previewURL == nil)
        #expect(song.trackNumber == nil)
    }
}

// MARK: - Helpers

private extension RemoteSongMapperTests {
    func anyHTTPURLResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://itunes.apple.com/search")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    func makeEnvelopeData(songs: [[String: Any]]) -> Data {
        let envelope: [String: Any] = ["resultCount": songs.count, "results": songs]
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
