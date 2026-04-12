import SwiftUI
import TuneDomain

@MainActor
enum AlbumComposer {
    static func compose(
        collectionId: Int,
        songRepository: any SongRepository,
        router: AppRouter
    ) -> some View {
        let viewModel = AlbumViewModel(
            collectionId: collectionId,
            repository: songRepository,
            router: router
        )
        return AlbumView(viewModel: viewModel)
    }
}
