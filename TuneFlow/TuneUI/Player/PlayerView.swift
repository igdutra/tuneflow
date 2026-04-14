import SwiftUI
import TuneDomain

struct PlayerView: View {
    @State private var viewModel: PlayerViewModel

    init(viewModel: PlayerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                artworkSection
                    .padding(.top, 32)

                songInfoSection
                    .padding(.top, 40)
                    .padding(.horizontal, 24)

                progressSection
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                transportSection
                    .padding(.top, 32)

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.song.albumName ?? "Unknown Album")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: viewModel.didTapMoreOptions) {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Artwork

    private var artworkSection: some View {
        AsyncImage(url: viewModel.artworkURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.gray.opacity(0.3)
        }
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Song Info

    private var songInfoSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.song.trackName)
                    // Note: footnote is 34, mockup asks for 32
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(viewModel.song.artistName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 16) {
                Button(action: viewModel.didTapShuffle) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#8E8E93"))
                }
                .disabled(true)
                .opacity(0.5)

                Button(action: viewModel.didTapRepeat) {
                    Image(systemName: "repeat")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#8E8E93"))
                }
                .disabled(true)
                .opacity(0.5)
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#3A3A3C"))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: geo.size.width * viewModel.progress, height: 4)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .offset(x: max(0, geo.size.width * viewModel.progress - 6))
                }
                .frame(height: 12)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 12)

            HStack {
                Text(viewModel.currentTimeFormatted)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Text("-\(viewModel.remainingTimeFormatted)")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Transport

    private var transportSection: some View {
        HStack(spacing: 48) {
            Button(action: viewModel.didTapBackward) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            .disabled(true)
            .opacity(0.5)

            playPauseButton

            Button(action: viewModel.didTapForward) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            .disabled(true)
            .opacity(0.5)
        }
    }

    private var playPauseButton: some View {
        Button(action: viewModel.didTapPlayPause) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#3A3A3C").opacity(0.8))
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .offset(x: viewModel.isPlaying ? 0 : 2)
            }
        }
        .disabled(!viewModel.isReadyToPlay)
    }
}
