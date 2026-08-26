import Foundation
import Security
import Vision
import CoreImage
import UIKit

struct WikiImageCandidate: Identifiable, Hashable {
    let id: Int
    let title: String
    let imageURL: URL
    let pageURL: URL?
}

actor WikipediaImageService {
    static let shared = WikipediaImageService()

    private struct QueryResponse: Decodable {
        let query: Query?
    }

    private struct Query: Decodable {
        let pages: [String: Page]
    }

    private struct Page: Decodable {
        let pageid: Int?
        let title: String
        let fullurl: String?
        let thumbnail: ImageValue?
        let original: ImageValue?
    }

    private struct ImageValue: Decodable {
        let source: String
    }

    func imageForExactPage(_ title: String) async throws -> WikiImageCandidate? {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")!
        components.queryItems = [
            .init(name: "action", value: "query"),
            .init(name: "format", value: "json"),
            .init(name: "prop", value: "pageimages|info"),
            .init(name: "titles", value: title),
            .init(name: "piprop", value: "thumbnail|original"),
            .init(name: "pithumbsize", value: "1200"),
            .init(name: "inprop", value: "url"),
            .init(name: "redirects", value: "1")
        ]
        guard let url = components.url else { return nil }
        let response: QueryResponse = try await fetch(url)
        guard let page = response.query?.pages.values.first,
              let imageString = page.thumbnail?.source ?? page.original?.source,
              let imageURL = URL(string: imageString) else { return nil }
        return WikiImageCandidate(
            id: page.pageid ?? abs(page.title.hashValue),
            title: page.title,
            imageURL: imageURL,
            pageURL: page.fullurl.flatMap(URL.init(string:))
        )
    }

    func searchImages(for query: String, limit: Int = 12) async throws -> [WikiImageCandidate] {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return [] }

        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")!
        components.queryItems = [
            .init(name: "action", value: "query"),
            .init(name: "format", value: "json"),
            .init(name: "generator", value: "search"),
            .init(name: "gsrsearch", value: "\(cleaned) video game"),
            .init(name: "gsrnamespace", value: "0"),
            .init(name: "gsrlimit", value: String(limit)),
            .init(name: "prop", value: "pageimages|info"),
            .init(name: "piprop", value: "thumbnail|original"),
            .init(name: "pithumbsize", value: "900"),
            .init(name: "inprop", value: "url")
        ]
        guard let url = components.url else { return [] }
        let response: QueryResponse = try await fetch(url)
        let pages = response.query.map { Array($0.pages.values) } ?? []

        return pages.compactMap { page in
            guard let imageString = page.thumbnail?.source ?? page.original?.source,
                  let imageURL = URL(string: imageString) else { return nil }
            return WikiImageCandidate(
                id: page.pageid ?? abs(page.title.hashValue),
                title: page.title,
                imageURL: imageURL,
                pageURL: page.fullurl.flatMap(URL.init(string:))
            )
        }
        .sorted { lhs, rhs in
            let leftExact = lhs.title.localizedCaseInsensitiveContains(cleaned)
            let rightExact = rhs.title.localizedCaseInsensitiveContains(cleaned)
            if leftExact != rightExact { return leftExact }
            return lhs.title < rhs.title
        }
    }

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("GameShelf/1.0 (personal iOS app)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

struct RAWGGameResult: Identifiable, Hashable {
    let id: Int
    let title: String
    let released: String?
    let backgroundURL: URL?
    let platforms: [String]

    var year: Int? {
        guard let released, released.count >= 4 else { return nil }
        return Int(released.prefix(4))
    }
}

actor RAWGService {
    static let shared = RAWGService()

    private struct Response: Decodable {
        let results: [Game]
    }

    private struct Game: Decodable {
        let id: Int
        let name: String
        let released: String?
        let background_image: String?
        let platforms: [PlatformWrapper]?
    }

    private struct PlatformWrapper: Decodable {
        let platform: Platform
    }

    private struct Platform: Decodable {
        let name: String
    }

    func searchGames(query: String, apiKey: String) async throws -> [RAWGGameResult] {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !apiKey.isEmpty else { return [] }
        var components = URLComponents(string: "https://api.rawg.io/api/games")!
        components.queryItems = [
            .init(name: "key", value: apiKey),
            .init(name: "search", value: cleaned),
            .init(name: "search_precise", value: "true"),
            .init(name: "page_size", value: "10")
        ]
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.results.map {
            RAWGGameResult(
                id: $0.id,
                title: $0.name,
                released: $0.released,
                backgroundURL: $0.background_image.flatMap(URL.init(string:)),
                platforms: $0.platforms?.map { $0.platform.name } ?? []
            )
        }
    }
}

enum KeychainStore {
    private static let service = "com.gameshelf.app"
    private static let rawgAccount = "rawg-api-key"

    static func readRAWGKey() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: rawgAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else { return "" }
        return value
    }

    static func saveRAWGKey(_ value: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: rawgAccount
        ]
        SecItemDelete(base as CFDictionary)
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return }
        var add = base
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }
}


actor ConsoleArtworkStore {
    static let shared = ConsoleArtworkStore()

    private let fileManager = FileManager.default
    private let ciContext = CIContext()
    private let cacheVersion = "v3"

    func image(for consoleID: UUID, remoteURLString: String?) async -> UIImage? {
        guard let remoteURLString,
              let remoteURL = URL(string: remoteURLString) else { return nil }

        let cacheURL = cachedFileURL(for: consoleID, source: remoteURLString)
        if let data = try? Data(contentsOf: cacheURL), let cached = UIImage(data: data) {
            return cached
        }

        do {
            var request = URLRequest(url: remoteURL)
            request.timeoutInterval = 20
            request.setValue("GameShelf/1.1 (personal iOS app)", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let sourceImage = UIImage(data: data) else { return nil }

            let prepared = backgroundRemovedImage(from: sourceImage) ?? sourceImage

            if let png = prepared.pngData() {
                try? ensureCacheDirectory()
                try? png.write(to: cacheURL, options: .atomic)
            }

            return prepared
        } catch {
            return nil
        }
    }

    func clearCache() {
        let directory = cacheDirectory
        try? fileManager.removeItem(at: directory)
    }

    private func backgroundRemovedImage(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()

        do {
            try handler.perform([request])
            guard let observation = request.results?.first,
                  !observation.allInstances.isEmpty else { return nil }

            // Keeping all detected foreground instances works well for console
            // bundles that include a controller while still removing the photo
            // or white studio background.
            let pixelBuffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )

            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            guard !ciImage.extent.isEmpty,
                  let output = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }

            return UIImage(cgImage: output, scale: image.scale, orientation: .up)
        } catch {
            return nil
        }
    }

    private var cacheDirectory: URL {
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("ConsoleArtwork", isDirectory: true)
    }

    private func ensureCacheDirectory() throws {
        try fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    private func cachedFileURL(for id: UUID, source: String) -> URL {
        let signature = stableHash(source)
        return cacheDirectory.appendingPathComponent("\(cacheVersion)-\(id.uuidString)-\(signature).png")
    }

    /// Stable FNV-1a hash used only to invalidate an artwork cache entry when
    /// its remote source URL changes. It is not used for security.
    private func stableHash(_ string: String) -> String {
        var hash: UInt64 = 14695981039346656037
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return String(hash, radix: 16)
    }
}
