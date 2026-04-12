import TuneDomain
import SwiftUI

@MainActor
@Observable
final class MoreOptionsViewModel {
    private let song: Song
    private let router: AppRouter

    var songTitle: String { song.trackName }
    var artistName: String { song.artistName }

    init(song: Song, router: AppRouter) {
        self.song = song
        self.router = router
    }

    func viewAlbum() {
        router.dismissSheet()
        router.push(.album(collectionId: song.collectionId))
    }
}
