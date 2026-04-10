import Foundation

public protocol SongRepository: Sendable {
    func search(query: String, limit: Int, offset: Int) async throws -> [Song]
}
