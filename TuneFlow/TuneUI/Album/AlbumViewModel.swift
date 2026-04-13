import TuneDomain
import SwiftUI

@MainActor
@Observable
final class AlbumViewModel {
    private let collectionId: Int
    private let repository: any SongRepository
    private let router: AppRouter

    private(set) var state: ViewState = .idle
    private(set) var album: Album?

    var title: String { album?.title ?? "" }
    var artistName: String { album?.artistName ?? "" }
    var artworkURL: URL? { album?.artworkURL }
    var tracks: [Song] { album?.tracks ?? [] }

    init(collectionId: Int, repository: any SongRepository, router: AppRouter) {
        self.collectionId = collectionId
        self.repository = repository
        self.router = router
    }

    func load() async {
        state = .loading
        do {
            album = try await repository.fetchAlbum(collectionId: collectionId)
            state = .loaded
        } catch {
            state = .error
            // TODO: save error
        }
    }
}
