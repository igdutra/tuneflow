import Foundation

public protocol RecentlyPlayedRepository: Sendable {
    func save(_ song: Song) async throws
    func loadRecent(limit: Int) async throws -> [Song]
}
