import SwiftUI
import TuneDomain

@MainActor
enum PlayerComposer {
    static func compose(
        song: Song,
        queue: [Song],
        currentIndex: Int,
        audioService: any AudioPlayerService,
        recentlyPlayedRepository: any RecentlyPlayedRepository,
        trackScreenViewed: @escaping TrackPlayerScreenViewed,
        router: AppRouter
    ) -> some View {
        let viewModel = PlayerViewModel(
            song: song,
            queue: queue,
            currentIndex: currentIndex,
            audioService: audioService,
            recentlyPlayedRepository: recentlyPlayedRepository,
            trackScreenViewed: trackScreenViewed,
            router: router
        )
        return PlayerView(viewModel: viewModel)
    }
}
