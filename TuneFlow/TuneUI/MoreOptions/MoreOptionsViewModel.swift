import TuneDomain

@MainActor
@Observable
final class MoreOptionsViewModel {
    private let song: Song

    var songTitle: String { song.trackName }
    var artistName: String { song.artistName }

    init(song: Song) {
        self.song = song
    }

    // Track 7 stub — no-op until album route exists
    func viewAlbum() {}
}
