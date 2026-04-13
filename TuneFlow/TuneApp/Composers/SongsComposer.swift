import SwiftUI
import TuneDomain

@MainActor
enum SongsComposer {
    static func compose(
        songRepository: any SongRepository,
        recentlyPlayedRepository: any RecentlyPlayedRepository,
        router: AppRouter
    ) -> some View {
        let viewModel = SongsViewModel(
            repository: songRepository,
            recentlyPlayedRepository: recentlyPlayedRepository,
            router: router
        )
        return SongsView(viewModel: viewModel)
    }
}
