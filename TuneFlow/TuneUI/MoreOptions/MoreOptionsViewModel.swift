import TuneDomain
import SwiftUI

@MainActor
@Observable
final class MoreOptionsViewModel {
    private let song: Song
    private let router: AppRouter

    var songTitle: String { song.trackName }
    var artistName: String { song.artistName }
    var canViewAlbum: Bool { song.collectionId != nil }

    init(song: Song, router: AppRouter) {
        self.song = song
        self.router = router
    }

    func viewAlbum() {
        guard let collectionId = song.collectionId else { return }
        router.dismissSheet()
        router.push(.album(collectionId: collectionId))
    }
}
