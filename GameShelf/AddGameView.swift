import SwiftUI
import SwiftData

struct AddGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let console: ConsoleSystem

    @State private var title = ""
    @State private var rawgResults: [RAWGGameResult] = []
    @State private var selectedRAWG: RAWGGameResult?
    @State private var coverResults: [WikiImageCandidate] = []
    @State private var selectedCover: WikiImageCandidate?
    @State private var status: GameStatus = .playing
    @State private var rating = 0
    @State private var isFavorite = false
    @State private var notes = ""
    @State private var isSearchingGames = false
    @State private var isSearchingCovers = false
    @State private var errorMessage: String?
    @State private var step = 1

    private var rawgKey: String { KeychainStore.readRAWGKey() }

    var body: some View {
        NavigationStack {
            Form {
                if step == 1 { gameSearchSection }
                if step == 2 { coverSection }
                if step == 3 { detailsSection }
            }
            .navigationTitle("Añadir juego")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if step == 3 {
                        Button("Guardar") { save() }
                            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .alert("No se pudo completar la búsqueda", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Aceptar", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Error desconocido")
            }
        }
    }

    @ViewBuilder
    private var gameSearchSection: some View {
        Section("1. ¿Qué juego quieres añadir?") {
            TextField("Ej. Resident Evil 4", text: $title)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .onSubmit { Task { await identifyGame() } }

            Button {
                Task { await identifyGame() }
            } label: {
                HStack {
                    Label(rawgKey.isEmpty ? "Buscar carátulas" : "Buscar juego", systemImage: "magnifyingglass")
                    Spacer()
                    if isSearchingGames { ProgressView() }
                }
            }
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearchingGames)
        }

        if !rawgKey.isEmpty && !rawgResults.isEmpty {
            Section("Coincidencias de RAWG") {
                ForEach(rawgResults) { result in
                    Button {
                        selectedRAWG = result
                        title = result.title
                        Task { await searchCovers() }
                    } label: {
                        HStack(spacing: 12) {
                            AsyncImage(url: result.backgroundURL) { phase in
                                if case .success(let image) = phase {
                                    image.resizable().scaledToFill()
                                } else {
                                    Rectangle().fill(.quaternary)
                                }
                            }
                            .frame(width: 66, height: 46)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(result.title).foregroundStyle(.primary)
                                HStack(spacing: 5) {
                                    if let year = result.year { Text(String(year)) }
                                    if !result.platforms.isEmpty { Text("• \(result.platforms.prefix(2).joined(separator: ", "))") }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }

        if rawgKey.isEmpty {
            Section {
                Label("RAWG es opcional. Sin clave, GameShelf busca directamente imágenes relacionadas en Wikipedia/Wikimedia.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var coverSection: some View {
        Section("2. Elige una carátula") {
            if isSearchingCovers {
                HStack { Spacer(); ProgressView("Buscando imágenes…"); Spacer() }
                    .padding(.vertical, 24)
            } else if coverResults.isEmpty {
                ContentUnavailableView("Sin imágenes", systemImage: "photo", description: Text("Puedes continuar sin carátula o volver a buscar."))
                Button("Buscar de nuevo") { Task { await searchCovers() } }
                Button("Continuar sin carátula") { step = 3 }
            } else {
                CoverPickerGrid(results: coverResults, selected: $selectedCover)
                Button("Usar esta carátula") { step = 3 }
                    .disabled(selectedCover == nil)
                Button("Continuar sin carátula") {
                    selectedCover = nil
                    step = 3
                }
            }
        }

        Section {
            Button("Volver") { step = 1 }
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        Section("3. Detalles") {
            TextField("Título", text: $title)
            Picker("Estado", selection: $status) {
                ForEach(GameStatus.allCases) { Text($0.rawValue).tag($0) }
            }
            Toggle("Favorito", isOn: $isFavorite)

            VStack(alignment: .leading, spacing: 8) {
                Text("Valoración")
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            rating = rating == star ? 0 : star
                        } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            TextField("Notas (opcional)", text: $notes, axis: .vertical)
                .lineLimit(3...7)
        }

        if let cover = selectedCover {
            Section("Carátula seleccionada") {
                AsyncImage(url: cover.imageURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFit()
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxHeight: 260)
                if let page = cover.pageURL {
                    Link("Ver fuente en Wikipedia", destination: page)
                }
            }
        }

        Section {
            Button("Cambiar carátula") { step = 2 }
        }
    }

    @MainActor
    private func identifyGame() async {
        selectedRAWG = nil
        rawgResults = []
        if rawgKey.isEmpty {
            await searchCovers()
            return
        }

        isSearchingGames = true
        defer { isSearchingGames = false }
        do {
            rawgResults = try await RAWGService.shared.searchGames(query: title, apiKey: rawgKey)
            if rawgResults.isEmpty {
                await searchCovers()
            }
        } catch {
            // Degrade gracefully: cover search remains available without RAWG.
            await searchCovers()
        }
    }

    @MainActor
    private func searchCovers() async {
        isSearchingCovers = true
        step = 2
        defer { isSearchingCovers = false }
        do {
            coverResults = try await WikipediaImageService.shared.searchImages(for: title)
            selectedCover = coverResults.first
        } catch {
            coverResults = []
            errorMessage = "No se han podido consultar las imágenes en este momento. Puedes guardar el juego sin carátula."
        }
    }

    @MainActor
    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let game = GameEntry(
            title: trimmed,
            releaseYear: selectedRAWG?.year,
            coverURL: selectedCover?.imageURL.absoluteString,
            coverSourceURL: selectedCover?.pageURL?.absoluteString,
            rawgID: selectedRAWG?.id,
            rawgBackgroundURL: selectedRAWG?.backgroundURL?.absoluteString,
            status: status,
            rating: rating,
            isFavorite: isFavorite,
            notes: notes,
            console: console
        )
        modelContext.insert(game)
        console.games.append(game)
        try? modelContext.save()
        dismiss()
    }
}

struct CoverPickerGrid: View {
    let results: [WikiImageCandidate]
    @Binding var selected: WikiImageCandidate?
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(results) { result in
                Button {
                    selected = result
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        AsyncImage(url: result.imageURL) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            } else {
                                Rectangle().fill(.quaternary).overlay { ProgressView() }
                            }
                        }
                        .aspectRatio(2.0 / 3.0, contentMode: .fill)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selected?.id == result.id ? Color.accentColor : Color.clear, lineWidth: 4)
                        }
                        Text(result.title)
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
