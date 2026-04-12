import TuneDomain

enum AppRoute: Hashable {
    case player(Song)
    case album(collectionId: Int)
}
