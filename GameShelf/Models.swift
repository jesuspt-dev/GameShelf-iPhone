import Foundation
import SwiftData

@Model
final class ConsoleSystem {
    var id: UUID
    var name: String
    var wikipediaTitle: String
    var imageURL: String?
    var sourcePageURL: String?
    var createdAt: Date
    var sortOrder: Int

    var games: [GameEntry]

    init(
        id: UUID = UUID(),
        name: String,
        wikipediaTitle: String,
        imageURL: String? = nil,
        sourcePageURL: String? = nil,
        createdAt: Date = .now,
        sortOrder: Int = 0,
        games: [GameEntry] = []
    ) {
        self.id = id
        self.name = name
        self.wikipediaTitle = wikipediaTitle
        self.imageURL = imageURL
        self.sourcePageURL = sourcePageURL
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.games = games
    }
}

@Model
final class GameEntry {
    var id: UUID
    var title: String
    var releaseYear: Int?
    var coverURL: String?
    var coverSourceURL: String?
    var rawgID: Int?
    var rawgBackgroundURL: String?
    var statusRaw: String
    var rating: Int
    var isFavorite: Bool
    var notes: String
    var addedAt: Date
    var console: ConsoleSystem?

    init(
        id: UUID = UUID(),
        title: String,
        releaseYear: Int? = nil,
        coverURL: String? = nil,
        coverSourceURL: String? = nil,
        rawgID: Int? = nil,
        rawgBackgroundURL: String? = nil,
        status: GameStatus = .playing,
        rating: Int = 0,
        isFavorite: Bool = false,
        notes: String = "",
        addedAt: Date = .now,
        console: ConsoleSystem? = nil
    ) {
        self.id = id
        self.title = title
        self.releaseYear = releaseYear
        self.coverURL = coverURL
        self.coverSourceURL = coverSourceURL
        self.rawgID = rawgID
        self.rawgBackgroundURL = rawgBackgroundURL
        self.statusRaw = status.rawValue
        self.rating = rating
        self.isFavorite = isFavorite
        self.notes = notes
        self.addedAt = addedAt
        self.console = console
    }

    var status: GameStatus {
        get { GameStatus(rawValue: statusRaw) ?? .playing }
        set { statusRaw = newValue.rawValue }
    }
}

enum GameStatus: String, CaseIterable, Identifiable, Hashable {
    case playing = "Jugando"
    case completed = "Completado"
    case backlog = "Pendiente"
    case paused = "Pausado"
    case abandoned = "Abandonado"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .playing: "play.circle.fill"
        case .completed: "checkmark.circle.fill"
        case .backlog: "clock.fill"
        case .paused: "pause.circle.fill"
        case .abandoned: "xmark.circle.fill"
        }
    }
}

struct ConsolePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let wikipediaTitle: String
    let symbol: String

    static let all: [ConsolePreset] = [
        .init(id: "pc", name: "PC", wikipediaTitle: "Computer case", symbol: "desktopcomputer"),
        .init(id: "ps5", name: "PlayStation 5", wikipediaTitle: "PlayStation 5", symbol: "playstation.logo"),
        .init(id: "ps4", name: "PlayStation 4", wikipediaTitle: "PlayStation 4", symbol: "playstation.logo"),
        .init(id: "ps3", name: "PlayStation 3", wikipediaTitle: "PlayStation 3", symbol: "playstation.logo"),
        .init(id: "ps2", name: "PlayStation 2", wikipediaTitle: "PlayStation 2", symbol: "playstation.logo"),
        .init(id: "psp", name: "PlayStation Portable", wikipediaTitle: "PlayStation Portable", symbol: "gamecontroller.fill"),
        .init(id: "vita", name: "PlayStation Vita", wikipediaTitle: "PlayStation Vita", symbol: "gamecontroller.fill"),
        .init(id: "xbox-series", name: "Xbox Series X|S", wikipediaTitle: "Xbox Series X and Series S", symbol: "xbox.logo"),
        .init(id: "xbox-one", name: "Xbox One", wikipediaTitle: "Xbox One", symbol: "xbox.logo"),
        .init(id: "xbox-360", name: "Xbox 360", wikipediaTitle: "Xbox 360", symbol: "xbox.logo"),
        .init(id: "xbox", name: "Xbox", wikipediaTitle: "Xbox (console)", symbol: "xbox.logo"),
        .init(id: "switch2", name: "Nintendo Switch 2", wikipediaTitle: "Nintendo Switch 2", symbol: "gamecontroller.fill"),
        .init(id: "switch", name: "Nintendo Switch", wikipediaTitle: "Nintendo Switch", symbol: "gamecontroller.fill"),
        .init(id: "wiiu", name: "Wii U", wikipediaTitle: "Wii U", symbol: "gamecontroller.fill"),
        .init(id: "wii", name: "Wii", wikipediaTitle: "Wii", symbol: "gamecontroller.fill"),
        .init(id: "3ds", name: "Nintendo 3DS", wikipediaTitle: "Nintendo 3DS", symbol: "gamecontroller.fill"),
        .init(id: "ds", name: "Nintendo DS", wikipediaTitle: "Nintendo DS", symbol: "gamecontroller.fill"),
        .init(id: "gamecube", name: "Nintendo GameCube", wikipediaTitle: "GameCube", symbol: "cube.fill"),
        .init(id: "gba", name: "Game Boy Advance", wikipediaTitle: "Game Boy Advance", symbol: "gamecontroller.fill"),
        .init(id: "gbc", name: "Game Boy Color", wikipediaTitle: "Game Boy Color", symbol: "gamecontroller.fill"),
        .init(id: "gb", name: "Game Boy", wikipediaTitle: "Game Boy", symbol: "gamecontroller.fill"),
        .init(id: "snes", name: "Super Nintendo", wikipediaTitle: "Super Nintendo Entertainment System", symbol: "gamecontroller.fill"),
        .init(id: "nes", name: "NES", wikipediaTitle: "Nintendo Entertainment System", symbol: "gamecontroller.fill"),
        .init(id: "dreamcast", name: "Sega Dreamcast", wikipediaTitle: "Dreamcast", symbol: "gamecontroller.fill"),
        .init(id: "saturn", name: "Sega Saturn", wikipediaTitle: "Sega Saturn", symbol: "gamecontroller.fill"),
        .init(id: "megadrive", name: "Mega Drive / Genesis", wikipediaTitle: "Sega Genesis", symbol: "gamecontroller.fill"),
        .init(id: "steamdeck", name: "Steam Deck", wikipediaTitle: "Steam Deck", symbol: "gamecontroller.fill")
    ]
}
