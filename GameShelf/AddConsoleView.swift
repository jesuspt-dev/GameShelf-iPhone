import SwiftUI
import SwiftData

struct AddConsoleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existing: [ConsoleSystem]

    @State private var searchText = ""
    @State private var loadingID: String?
    @State private var errorMessage: String?

    private var presets: [ConsolePreset] {
        let available = ConsolePreset.all.filter { preset in
            !existing.contains(where: { $0.name == preset.name })
        }
        guard !searchText.isEmpty else { return available }
        return available.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(presets) { preset in
                        Button {
                            Task { await add(preset) }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: preset.symbol)
                                    .font(.title2)
                                    .frame(width: 34)
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name).foregroundStyle(.primary)
                                    Text("Imagen recortada automáticamente")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if loadingID == preset.id {
                                    ProgressView()
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                }
                            }
                        }
                        .disabled(loadingID != nil)
                    }
                } footer: {
                    Text("GameShelf obtiene la imagen desde Wikipedia y elimina su fondo localmente con Apple Vision. El recorte se guarda solo en la caché del iPhone. Si no puede procesarse, se usa la imagen original o un icono de respaldo.")
                }
            }
            .navigationTitle("Añadir consola")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "PlayStation, Xbox, Nintendo…")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .alert("No se pudo cargar la imagen", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Continuar sin imagen") {
                    if let id = loadingID, let preset = ConsolePreset.all.first(where: { $0.id == id }) {
                        insert(preset, image: nil)
                    }
                    errorMessage = nil
                }
                Button("Cancelar", role: .cancel) { loadingID = nil }
            } message: {
                Text(errorMessage ?? "Error desconocido")
            }
        }
    }

    @MainActor
    private func add(_ preset: ConsolePreset) async {
        loadingID = preset.id
        do {
            let image = try await WikipediaImageService.shared.imageForExactPage(preset.wikipediaTitle)
            insert(preset, image: image)
        } catch {
            errorMessage = "No se ha podido consultar Wikipedia. Puedes añadir la consola igualmente y usar el icono de respaldo."
        }
    }

    @MainActor
    private func insert(_ preset: ConsolePreset, image: WikiImageCandidate?) {
        let nextOrder = (existing.map(\.sortOrder).max() ?? -1) + 1
        let console = ConsoleSystem(
            name: preset.name,
            wikipediaTitle: preset.wikipediaTitle,
            imageURL: image?.imageURL.absoluteString,
            sourcePageURL: image?.pageURL?.absoluteString,
            sortOrder: nextOrder
        )
        modelContext.insert(console)
        try? modelContext.save()
        loadingID = nil
        dismiss()
    }
}
