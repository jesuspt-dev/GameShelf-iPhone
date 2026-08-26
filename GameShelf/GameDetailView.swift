import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var game: GameEntry
    @State private var showingDelete = false
    @State private var showingCoverSearch = false

    var body: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 16) {
                    GameCoverView(game: game)
                        .frame(width: 125)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.title).font(.title3.bold())
                        if let year = game.releaseYear {
                            Text(String(year)).foregroundStyle(.secondary)
                        }
                        Label(game.status.rawValue, systemImage: game.status.systemImage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if game.rating > 0 {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= game.rating ? "star.fill" : "star")
                                }
                            }
                            .foregroundStyle(.yellow)
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Biblioteca") {
                Picker("Estado", selection: Binding(
                    get: { game.status },
                    set: { game.status = $0; save() }
                )) {
                    ForEach(GameStatus.allCases) { Text($0.rawValue).tag($0) }
                }
                Toggle("Favorito", isOn: Binding(
                    get: { game.isFavorite },
                    set: { game.isFavorite = $0; save() }
                ))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Valoración")
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                game.rating = game.rating == star ? 0 : star
                                save()
                            } label: {
                                Image(systemName: star <= game.rating ? "star.fill" : "star")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Section("Notas") {
                TextField("Añade notas sobre el juego", text: $game.notes, axis: .vertical)
                    .lineLimit(4...10)
                    .onSubmit { save() }
            }

            Section("Carátula") {
                Button("Buscar otra carátula") { showingCoverSearch = true }
                if let source = game.coverSourceURL, let url = URL(string: source) {
                    Link("Ver fuente de la imagen", destination: url)
                }
                if game.rawgID != nil {
                    Link("Datos del juego: RAWG", destination: URL(string: "https://rawg.io")!)
                }
            }

            Section {
                Button("Eliminar juego", role: .destructive) { showingDelete = true }
            }
        }
        .navigationTitle("Juego")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { save() }
        .sheet(isPresented: $showingCoverSearch) {
            ChangeCoverView(game: game)
        }
        .confirmationDialog("¿Eliminar \(game.title)?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                modelContext.delete(game)
                try? modelContext.save()
                dismiss()
            }
        }
    }

    private func save() { try? modelContext.save() }
}

private struct ChangeCoverView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var game: GameEntry
    @State private var results: [WikiImageCandidate] = []
    @State private var selected: WikiImageCandidate?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Buscando carátulas…").padding(.top, 80)
                } else if results.isEmpty {
                    ContentUnavailableView("Sin resultados", systemImage: "photo")
                        .padding(.top, 50)
                } else {
                    CoverPickerGrid(results: results, selected: $selected)
                        .padding()
                }
            }
            .navigationTitle("Cambiar carátula")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        game.coverURL = selected?.imageURL.absoluteString
                        game.coverSourceURL = selected?.pageURL?.absoluteString
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(selected == nil)
                }
            }
            .task {
                defer { isLoading = false }
                results = (try? await WikipediaImageService.shared.searchImages(for: game.title)) ?? []
                selected = results.first
            }
        }
    }
}
