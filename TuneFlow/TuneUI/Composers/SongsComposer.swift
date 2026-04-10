import SwiftUI
import TuneDomain

@MainActor
enum SongsComposer {
    static func compose(songRepository: any SongRepository, router: AppRouter) -> some View {
        let viewModel = SongsViewModel(repository: songRepository, router: router)
        return SongsView(viewModel: viewModel)
    }
}
