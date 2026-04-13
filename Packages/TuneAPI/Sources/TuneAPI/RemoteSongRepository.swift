import Foundation
import TuneDomain

public final class RemoteSongRepository: SongRepository {
    private let client: HTTPClient
    private let baseURL: URL
    private let lookupBaseURL: URL
    private let logger: LogHandling

    public init(client: HTTPClient, baseURL: URL, lookupBaseURL: URL, logger: LogHandling) {
        self.client = client
        self.baseURL = baseURL
        self.lookupBaseURL = lookupBaseURL
        self.logger = logger
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

        do {
            let (data, response) = try await client.get(from: url)
            return try RemoteSongMapper.map(data, response)
        } catch {
            logger.error("Search failed for query '\(query)': \(error)")
            throw error
        }
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

        do {
            let (data, response) = try await client.get(from: url)
            return try RemoteAlbumMapper.map(data, response)
        } catch {
            logger.error("Fetch album failed for collectionId \(collectionId): \(error)")
            throw error
        }
    }
}
