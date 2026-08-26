import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var consoles: [ConsoleSystem]

    @State private var showingAddConsole = false
    @State private var showingSettings = false
    @State private var searchText = ""

    // Two guaranteed equal-width columns avoid remote artwork influencing the
    // intrinsic width of a grid cell and pushing cards outside the screen.
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var orderedConsoles: [ConsoleSystem] {
        consoles.sorted { lhs, rhs in
            if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
            return lhs.createdAt < rhs.createdAt
        }
    }

    private var filteredConsoles: [ConsoleSystem] {
        guard !searchText.isEmpty else { return orderedConsoles }
        return orderedConsoles.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if consoles.isEmpty {
                    ContentUnavailableView {
                        Label("Tu colección empieza aquí", systemImage: "gamecontroller.fill")
                    } description: {
                        Text("Añade las consolas en las que juegas. Cada una tendrá su propia biblioteca de juegos.")
                    } actions: {
                        Button("Añadir primera consola") { showingAddConsole = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 90)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        librarySummary

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredConsoles) { console in
                                NavigationLink {
                                    ConsoleDetailView(console: console)
                                } label: {
                                    ConsoleCard(console: console)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .background {
                ZStack {
                    Color(uiColor: .systemBackground)
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.08),
                            .clear,
                            Color.indigo.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .ignoresSafeArea()
            }
            .navigationTitle("GameShelf")
            .searchable(text: $searchText, prompt: "Buscar consola")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                    Button { showingAddConsole = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAddConsole) { AddConsoleView() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .task {
                await refreshLegacyConsoleSourcesIfNeeded()
            }
        }
    }

    private var librarySummary: some View {
        let totalGames = orderedConsoles.reduce(0) { $0 + $1.games.count }
        return HStack(spacing: 14) {
            summaryMetric(value: "\(orderedConsoles.count)", label: orderedConsoles.count == 1 ? "consola" : "consolas", symbol: "rectangle.stack.fill")
            Divider().frame(height: 34)
            summaryMetric(value: "\(totalGames)", label: totalGames == 1 ? "juego" : "juegos", symbol: "gamecontroller.fill")
            Spacer(minLength: 0)
        }
        .padding(18)
        .glassCard()
    }

    private func summaryMetric(value: String, label: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.title3.bold())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    /// Updates old saved presets when a source page was improved in a newer
    /// GameShelf version. Existing game data is not touched.
    @MainActor
    private func refreshLegacyConsoleSourcesIfNeeded() async {
        var changed = false

        for console in consoles {
            guard let preset = ConsolePreset.all.first(where: { $0.name == console.name }),
                  console.wikipediaTitle != preset.wikipediaTitle else { continue }

            console.wikipediaTitle = preset.wikipediaTitle
            changed = true

            if let candidate = try? await WikipediaImageService.shared.imageForExactPage(preset.wikipediaTitle) {
                console.imageURL = candidate.imageURL.absoluteString
                console.sourcePageURL = candidate.pageURL?.absoluteString
            }
        }

        if changed {
            try? modelContext.save()
        }
    }
}

private struct ConsoleCard: View {
    let console: ConsoleSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            deviceStage

            VStack(alignment: .leading, spacing: 5) {
                Text(console.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)

                Text("\(console.games.count) \(console.games.count == 1 ? "juego" : "juegos")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
            .padding(.horizontal, 14)
            .padding(.top, 11)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.primary.opacity(0.07), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.08), radius: 14, y: 7)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var deviceStage: some View {
        ZStack {
            LinearGradient(
                colors: [Color.primary.opacity(0.035), Color.accentColor.opacity(0.055)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.accentColor.opacity(0.18), .clear],
                center: .center,
                startRadius: 8,
                endRadius: 95
            )

            ConsoleDeviceArtworkView(
                consoleID: console.id,
                urlString: console.imageURL,
                fallbackSymbol: fallbackSymbol
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
        .clipped()
    }

    private var fallbackSymbol: String {
        ConsolePreset.all.first(where: { $0.name == console.name })?.symbol ?? "gamecontroller.fill"
    }
}
