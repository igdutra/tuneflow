import Foundation

struct RemoteAlbumDTO: Decodable {
    let collectionId: Int
    let collectionName: String
    let artistName: String
    let artworkUrl100: String
}

struct RemoteLookupSongDTO: Decodable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let collectionName: String
    let collectionId: Int
    let artworkUrl100: String
    let previewUrl: String?
    let trackNumber: Int?
    let wrapperType: String
    let kind: String?
}

struct RemoteLookupPage: Decodable {
    let resultCount: Int
    let results: [RemoteLookupResult]
}

enum RemoteLookupResult: Decodable {
    case album(RemoteAlbumDTO)
    case song(RemoteLookupSongDTO)
    case unknown

    private enum CodingKeys: String, CodingKey {
        case wrapperType
        case kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let wrapperType = try container.decodeIfPresent(String.self, forKey: .wrapperType)
        let kind = try container.decodeIfPresent(String.self, forKey: .kind)

        if wrapperType == "collection" {
            self = .album(try RemoteAlbumDTO(from: decoder))
        } else if wrapperType == "track", kind == "song" {
            self = .song(try RemoteLookupSongDTO(from: decoder))
        } else {
            self = .unknown
        }
    }
}
