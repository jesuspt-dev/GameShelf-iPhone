import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rawgKey = ""
    @State private var saved = false
    @State private var artworkCacheCleared = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("RAWG API key (opcional)", text: $rawgKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button("Guardar clave") {
                        KeychainStore.saveRAWGKey(rawgKey.trimmingCharacters(in: .whitespacesAndNewlines))
                        saved = true
                    }

                    if saved {
                        Label("Guardada en el Keychain del iPhone", systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }

                    Link("Obtener una clave en RAWG", destination: URL(string: "https://rawg.io/apidocs")!)
                } header: {
                    Text("Búsqueda de juegos")
                } footer: {
                    Text("La clave no se almacena en GitHub ni en los archivos del proyecto. Si no configuras RAWG, la búsqueda de carátulas de Wikipedia/Wikimedia seguirá funcionando.")
                }

                Section {
                    Button {
                        Task {
                            await ConsoleArtworkStore.shared.clearCache()
                            artworkCacheCleared = true
                        }
                    } label: {
                        Label("Regenerar imágenes de consolas", systemImage: "wand.and.stars")
                    }

                    if artworkCacheCleared {
                        Label("Caché limpiada", systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Imágenes de consolas")
                } footer: {
                    Text("GameShelf elimina el fondo de las imágenes localmente con Apple Vision y guarda el resultado como PNG transparente en la caché. Al limpiar la caché, los recortes se regenerarán al volver a cargar las tarjetas o abrir de nuevo la app.")
                }

                Section("Fuentes") {
                    Link("Wikipedia / Wikimedia", destination: URL(string: "https://www.wikipedia.org")!)
                    Link("RAWG", destination: URL(string: "https://rawg.io")!)
                    Text("Cuando se utilizan datos o imágenes procedentes de RAWG, se muestra un enlace de atribución a RAWG en la ficha del juego.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Datos") {
                    Text("Tu colección se guarda localmente en el iPhone mediante SwiftData. No hay cuenta, servidor propio ni analítica.")
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
            }
            .onAppear { rawgKey = KeychainStore.readRAWGKey() }
        }
    }
}
