import TuneDomain

enum AppRoute: Hashable {
    case player(Song, queue: [Song], currentIndex: Int)
    case album(collectionId: Int)
}
