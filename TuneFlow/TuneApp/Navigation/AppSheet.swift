import TuneDomain

enum AppSheet: Identifiable {
    case moreOptions(Song)

    var id: String {
        switch self {
        case .moreOptions(let song): return "moreOptions-\(song.id)"
        }
    }
}
