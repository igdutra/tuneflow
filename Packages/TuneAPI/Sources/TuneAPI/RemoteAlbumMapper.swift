import Foundation
import TuneDomain

enum RemoteAlbumMapper {
    private static let okStatus = 200

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> Album {
        guard response.statusCode == okStatus else {
            throw RemoteSongRepositoryError.invalidData
        }

        let page: RemoteLookupPage
        do {
            page = try JSONDecoder().decode(RemoteLookupPage.self, from: data)
        } catch {
            throw RemoteSongRepositoryError.invalidData
        }

        guard let albumResult = page.results.compactMap({ result -> RemoteAlbumDTO? in
            if case .album(let dto) = result { return dto }
            return nil
        }).first else {
            throw RemoteSongRepositoryError.invalidData
        }

        guard let artworkURL = URL(string: albumResult.artworkUrl100) else {
            throw RemoteSongRepositoryError.invalidData
        }

        let tracks: [Song] = page.results.compactMap { result -> Song? in
            guard case .song(let dto) = result else { return nil }
            guard let trackArtworkURL = URL(string: dto.artworkUrl100) else { return nil }
            let previewURL = dto.previewUrl.flatMap { URL(string: $0) }
            return Song(
                id: dto.trackId,
                trackName: dto.trackName,
                artistName: dto.artistName,
                albumName: dto.collectionName,
                collectionId: dto.collectionId,
                artworkURL: trackArtworkURL,
                previewURL: previewURL,
                trackNumber: dto.trackNumber
            )
        }

        return Album(
            id: albumResult.collectionId,
            title: albumResult.collectionName,
            artistName: albumResult.artistName,
            artworkURL: artworkURL,
            tracks: tracks
        )
    }
}
