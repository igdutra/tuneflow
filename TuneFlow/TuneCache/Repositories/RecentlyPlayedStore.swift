import Foundation
import TuneDomain

protocol RecentlyPlayedStore: Sendable {
    func insert(_ song: Song) async throws
    func retrieveAll() async throws -> [StoredSong]
}
