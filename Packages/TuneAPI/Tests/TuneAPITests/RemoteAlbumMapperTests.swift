import Testing
import Foundation
import TuneDomain
@testable import TuneAPI

struct RemoteAlbumMapperTests {

    // MARK: - Success

    @Test func map_onValidLookupResponse_deliversAlbumWithCorrectMetadata() throws {
        let albumDTO = makeAlbumJSON(collectionId: 123, title: "Homework", artistName: "Daft Punk", artworkUrl100: "https://artwork.com/100x100.jpg")
        let data = makeLookupData(results: [albumDTO])

        let result = try RemoteAlbumMapper.map(data, anyHTTPURLResponse(statusCode: 200))

        #expect(result.id == 123)
        #expect(result.title == "Homework")
        #expect(result.artistName == "Daft Punk")
        #expect(result.artworkURL == URL(string: "https://artwork.com/100x100.jpg")!)
    }

    @Test func map_onValidLookupResponse_deliversOrderedTracks() throws {
        let albumDTO = makeAlbumJSON(collectionId: 123, title: "Homework", artistName: "Daft Punk", artworkUrl100: "https://artwork.com/100x100.jpg")
        let track1 = makeTrackJSON(trackId: 1, trackName: "Around the World", trackNumber: 1, collectionId: 123)
        let track2 = makeTrackJSON(trackId: 2, trackName: "Harder, Better, Faster, Stronger", trackNumber: 2, collectionId: 123)
        let track3 = makeTrackJSON(trackId: 3, trackName: "Digital Love", trackNumber: 3, collectionId: 123)
        let data = makeLookupData(results: [albumDTO, track1, track2, track3])

        let result = try RemoteAlbumMapper.map(data, anyHTTPURLResponse(statusCode: 200))

        #expect(result.tracks.count == 3)
        #expect(result.tracks[0].trackName == "Around the World")
        #expect(result.tracks[1].trackName == "Harder, Better, Faster, Stronger")
        #expect(result.tracks[2].trackName == "Digital Love")
    }

    @Test func map_onValidLookupResponse_mapsCollectionIdOnEachTrack() throws {
        let albumDTO = makeAlbumJSON(collectionId: 123, title: "Homework", artistName: "Daft Punk", artworkUrl100: "https://artwork.com/100x100.jpg")
        let track = makeTrackJSON(trackId: 1, trackName: "Around the World", trackNumber: 1, collectionId: 123)
        let data = makeLookupData(results: [albumDTO, track])

        let result = try RemoteAlbumMapper.map(data, anyHTTPURLResponse(statusCode: 200))

        let firstTrack = try #require(result.tracks.first)
        #expect(firstTrack.collectionId == 123)
    }

    @Test func map_onValidLookupResponse_handlesOptionalTrackFields() throws {
        let albumDTO = makeAlbumJSON(collectionId: 123, title: "Homework", artistName: "Daft Punk", artworkUrl100: "https://artwork.com/100x100.jpg")
        let track = makeTrackJSON(trackId: 1, trackName: "Around the World", trackNumber: nil, collectionId: 123, includePreviewUrl: false)
        let data = makeLookupData(results: [albumDTO, track])

        let result = try RemoteAlbumMapper.map(data, anyHTTPURLResponse(statusCode: 200))

        let firstTrack = try #require(result.tracks.first)
        #expect(firstTrack.previewURL == nil)
        #expect(firstTrack.trackNumber == nil)
    }

    // MARK: - Failures

    @Test(arguments: [199, 201, 300, 400, 500])
    func map_onNon200HTTPResponse_throwsInvalidData(statusCode: Int) throws {
        let data = makeLookupData(results: [])

        #expect(throws: RemoteSongRepositoryError.invalidData) {
            try RemoteAlbumMapper.map(data, anyHTTPURLResponse(statusCode: statusCode))
        }
    }

    @Test func map_onMalformedJSON_throwsInvalidData() throws {
        #expect(throws: RemoteSongRepositoryError.invalidData) {
            try RemoteAlbumMapper.map(Data("not json".utf8), anyHTTPURLResponse(statusCode: 200))
        }
    }

    @Test func map_onMissingAlbumResult_throwsInvalidData() throws {
        let track = makeTrackJSON(trackId: 1, trackName: "Around the World", trackNumber: 1, collectionId: 123)
        let data = makeLookupData(results: [track])

        #expect(throws: RemoteSongRepositoryError.invalidData) {
            try RemoteAlbumMapper.map(data, anyHTTPURLResponse(statusCode: 200))
        }
    }

    @Test func map_onEmptyResults_throwsInvalidData() throws {
        let data = makeLookupData(results: [])

        #expect(throws: RemoteSongRepositoryError.invalidData) {
            try RemoteAlbumMapper.map(data, anyHTTPURLResponse(statusCode: 200))
        }
    }
}

// MARK: - Helpers

private extension RemoteAlbumMapperTests {
    func anyHTTPURLResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://itunes.apple.com/lookup")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    func makeLookupData(results: [[String: Any]]) -> Data {
        let envelope: [String: Any] = [
            "resultCount": results.count,
            "results": results
        ]
        return try! JSONSerialization.data(withJSONObject: envelope)
    }

    func makeAlbumJSON(
        collectionId: Int,
        title: String,
        artistName: String,
        artworkUrl100: String
    ) -> [String: Any] {
        [
            "wrapperType": "collection",
            "collectionId": collectionId,
            "collectionName": title,
            "artistName": artistName,
            "artworkUrl100": artworkUrl100
        ]
    }

    func makeTrackJSON(
        trackId: Int,
        trackName: String,
        trackNumber: Int?,
        collectionId: Int,
        includePreviewUrl: Bool = true
    ) -> [String: Any] {
        var json: [String: Any] = [
            "wrapperType": "track",
            "kind": "song",
            "trackId": trackId,
            "trackName": trackName,
            "artistName": "Daft Punk",
            "collectionName": "Homework",
            "collectionId": collectionId,
            "artworkUrl100": "https://artwork.com/track/100x100.jpg"
        ]
        if let trackNumber {
            json["trackNumber"] = trackNumber
        }
        if includePreviewUrl {
            json["previewUrl"] = "https://preview.com/track.m4a"
        }
        return json
    }
}
