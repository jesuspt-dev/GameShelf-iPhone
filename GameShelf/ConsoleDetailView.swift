import SwiftUI
import SwiftData

struct ConsoleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var console: ConsoleSystem

    @State private var showingAddGame = false
    @State private var showingDeleteConfirmation = false
    @State private var searchText = ""
    @State private var statusFilter: GameStatus?

    private let columns = [GridItem(.adaptive(minimum: 135), spacing: 14)]

    private var filteredGames: [GameEntry] {
        console.games
            .filter { game in
                (searchText.isEmpty || game.title.localizedCaseInsensitiveContains(searchText)) &&
                (statusFilter == nil || game.status == statusFilter)
            }
            .sorted { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite }
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                statusPicker

                if console.games.isEmpty {
                    ContentUnavailableView {
                        Label("Sin juegos todavía", systemImage: "gamecontroller")
                    } description: {
                        Text("Añade el primer juego y GameShelf buscará carátulas relacionadas.")
                    } actions: {
                        Button("Añadir juego") { showingAddGame = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 30)
                } else if filteredGames.isEmpty {
                    ContentUnavailableView(
                        "Sin resultados",
                        systemImage: "magnifyingglass",
                        description: Text("No hay juegos que coincidan con la búsqueda o el filtro actual.")
                    )
                    .padding(.top, 30)
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(filteredGames) { game in
                            NavigationLink {
                                GameDetailView(game: game)
                            } label: {
                                GameTile(game: game)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(console.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Buscar juego")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingAddGame = true } label: { Image(systemName: "plus") }
                Menu {
                    if let source = console.sourcePageURL, let url = URL(string: source) {
                        Link("Fuente de la imagen", destination: url)
                    }
                    Button("Eliminar consola", role: .destructive) { showingDeleteConfirmation = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddGame) {
            AddGameView(console: console)
        }
        .confirmationDialog("¿Eliminar \(console.name)?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Eliminar consola y sus juegos", role: .destructive) {
                for game in console.games {
                    modelContext.delete(game)
                }
                modelContext.delete(console)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("También se borrarán todos los juegos guardados dentro de esta consola.")
        }
    }

    private var hero: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color.primary.opacity(0.04), Color.accentColor.opacity(0.09)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [Color.accentColor.opacity(0.20), .clear],
                    center: .center,
                    startRadius: 12,
                    endRadius: 150
                )

                ConsoleDeviceArtworkView(
                    consoleID: console.id,
                    urlString: console.imageURL,
                    fallbackSymbol: ConsolePreset.all.first(where: { $0.name == console.name })?.symbol ?? "gamecontroller.fill"
                )
                .padding(.horizontal, 36)
                .padding(.vertical, 22)
            }
            .frame(height: 205)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(console.name)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Text("\(console.games.count) \(console.games.count == 1 ? "juego" : "juegos")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "gamecontroller.fill")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.primary.opacity(0.07), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.07), radius: 18, y: 8)
    }

    private var statusPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Todos", selected: statusFilter == nil) { statusFilter = nil }
                ForEach(GameStatus.allCases) { status in
                    FilterChip(title: status.rawValue, selected: statusFilter == status) { statusFilter = status }
                }
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
                .foregroundStyle(selected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

private struct GameTile: View {
    let game: GameEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GameCoverView(game: game)
            Text(game.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
            HStack(spacing: 5) {
                Image(systemName: game.status.systemImage)
                Text(game.status.rawValue)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
