import SwiftUI
import UIKit

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 0.8)
            }
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCardModifier()) }
}

/// Artwork specifically for console hardware. It downloads the Wikipedia
/// product image once, removes the background locally with Apple Vision, and
/// keeps a transparent PNG in the app cache. Nothing is uploaded anywhere.
struct ConsoleDeviceArtworkView: View {
    let consoleID: UUID
    let urlString: String?
    let fallbackSymbol: String

    @State private var image: UIImage?
    @State private var isLoading = false

    private var taskKey: String {
        "\(consoleID.uuidString)|\(urlString ?? "none")"
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .shadow(color: .black.opacity(0.22), radius: 8, y: 5)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if isLoading, urlString != nil {
                ProgressView()
                    .controlSize(.regular)
            } else {
                Image(systemName: fallbackSymbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(34)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: taskKey) {
            isLoading = urlString != nil
            image = await ConsoleArtworkStore.shared.image(
                for: consoleID,
                remoteURLString: urlString
            )
            isLoading = false
        }
        .animation(.easeOut(duration: 0.24), value: image != nil)
    }
}

struct RemoteArtworkView: View {
    let urlString: String?
    let fallbackSymbol: String
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Rectangle().fill(.quaternary)
                            ProgressView()
                        }
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: contentMode)
                    case .failure:
                        fallback
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
    }

    private var fallback: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Image(systemName: fallbackSymbol)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

struct GameCoverView: View {
    let game: GameEntry

    var body: some View {
        RemoteArtworkView(urlString: game.coverURL ?? game.rawgBackgroundURL, fallbackSymbol: "gamecontroller.fill")
            .aspectRatio(2.0 / 3.0, contentMode: .fill)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if game.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption.weight(.bold))
                        .padding(7)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(8)
                }
            }
    }
}
