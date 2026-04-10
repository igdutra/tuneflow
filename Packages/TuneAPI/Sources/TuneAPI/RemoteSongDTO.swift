import Foundation

struct RemoteSongDTO: Decodable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let collectionName: String
    let artworkUrl100: String
    let previewUrl: String?
    let trackNumber: Int?
}

struct RemoteSearchPage: Decodable {
    let resultCount: Int
    let results: [RemoteSongDTO]
}
