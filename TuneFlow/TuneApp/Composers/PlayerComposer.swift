import SwiftUI
import TuneDomain

@MainActor
enum PlayerComposer {
    static func compose(
        song: Song,
        queue: [Song],
        currentIndex: Int,
        router: AppRouter
    ) -> some View {
        let audioService = AVAudioPlayerService()
        let viewModel = PlayerViewModel(
            song: song,
            queue: queue,
            currentIndex: currentIndex,
            audioService: audioService,
            router: router
        )
        return PlayerView(viewModel: viewModel)
    }
}
