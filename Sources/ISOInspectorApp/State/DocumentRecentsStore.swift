#if canImport(Foundation)
  import Foundation

  struct DocumentRecent: Codable, Equatable, Identifiable, Sendable {
    var url: URL
    var bookmarkIdentifier: UUID?
    var bookmarkData: Data?
    var displayName: String
    var lastOpened: Date

    var id: URL { url }

    init(
      url: URL,
      bookmarkIdentifier: UUID? = nil,
      bookmarkData: Data? = nil,
      displayName: String,
      lastOpened: Date
    ) {
      self.url = url
      self.bookmarkIdentifier = bookmarkIdentifier
      self.bookmarkData = bookmarkData
      self.displayName = displayName
      self.lastOpened = lastOpened
    }
  }

  protocol DocumentRecentsStoring {
    func load() throws -> [DocumentRecent]
    func save(_ recents: [DocumentRecent]) throws
  }

  struct DocumentRecentsStore: DocumentRecentsStoring {
    private let storageURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directory: URL, fileName: String = "Recents.json") {
      self.storageURL = directory.appendingPathComponent(fileName, isDirectory: false)
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      self.encoder = encoder
      self.decoder = JSONDecoder()
    }

    func load() throws -> [DocumentRecent] {
      guard FileManager.default.fileExists(atPath: storageURL.path) else {
        return []
      }
      let data = try Data(contentsOf: storageURL)
      let entries = try decoder.decode([DocumentRecent].self, from: data)
      return entries.map { entry in
        var normalized = entry
        if normalized.displayName.isEmpty {
          normalized.displayName = normalized.url.lastPathComponent
        }
        return normalized
      }
    }

    func save(_ recents: [DocumentRecent]) throws {
      let data = try encoder.encode(recents)
      let directory = storageURL.deletingLastPathComponent()
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try data.write(to: storageURL, options: .atomic)
    }
  }
#endif
