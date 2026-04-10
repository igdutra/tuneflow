import SwiftUI
import TuneDomain

@MainActor
enum SongsComposer {
    static func compose(songRepository: SongRepository) -> some View {
        let viewModel = SongsViewModel(repository: songRepository)
        return SongsView(viewModel: viewModel)
    }
}
