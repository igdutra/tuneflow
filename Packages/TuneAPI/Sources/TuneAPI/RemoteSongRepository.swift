import Foundation
import TuneDomain

public final class RemoteSongRepository: SongRepository {
    private let client: HTTPClient
    private let baseURL: URL
    private let lookupBaseURL: URL

    public init(client: HTTPClient, baseURL: URL, lookupBaseURL: URL) {
        self.client = client
        self.baseURL = baseURL
        self.lookupBaseURL = lookupBaseURL
    }

    public func search(query: String, limit: Int, offset: Int) async throws -> [Song] {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw RemoteSongRepositoryError.invalidData
        }
        components.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        guard let url = components.url else {
            throw RemoteSongRepositoryError.invalidData
        }

        let (data, response) = try await client.get(from: url)
        return try RemoteSongMapper.map(data, response)
    }

    public func fetchAlbum(collectionId: Int) async throws -> Album {
        guard var components = URLComponents(url: lookupBaseURL, resolvingAgainstBaseURL: false) else {
            throw RemoteSongRepositoryError.invalidData
        }
        components.queryItems = [
            URLQueryItem(name: "id", value: String(collectionId)),
            URLQueryItem(name: "entity", value: "song"),
        ]
        guard let url = components.url else {
            throw RemoteSongRepositoryError.invalidData
        }

        let (data, response) = try await client.get(from: url)
        return try RemoteAlbumMapper.map(data, response)
    }
}
