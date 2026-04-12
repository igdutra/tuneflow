import Foundation
import TuneDomain

enum RemoteSongMapper {
    private static let okStatus = 200

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [Song] {
        guard response.statusCode == okStatus else {
            throw RemoteSongRepositoryError.invalidData
        }

        let envelope: RemoteSearchPage
        do {
            envelope = try JSONDecoder().decode(RemoteSearchPage.self, from: data)
        } catch {
            throw RemoteSongRepositoryError.invalidData
        }

        return envelope.results.compactMap(toSong(from:))
    }

    private static func toSong(from dto: RemoteSongDTO) -> Song? {
        guard let artworkURL = URL(string: dto.artworkUrl100) else { return nil }
        let previewURL = dto.previewUrl.flatMap { URL(string: $0) }
        return Song(
            id: dto.trackId,
            trackName: dto.trackName,
            artistName: dto.artistName,
            albumName: dto.collectionName,
            collectionId: dto.collectionId,
            artworkURL: artworkURL,
            previewURL: previewURL,
            trackNumber: dto.trackNumber
        )
    }
}
