import SwiftUI
import SwiftData

@main
struct GameShelfApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [ConsoleSystem.self, GameEntry.self])
    }
}
