import Foundation

/// Persists security-scoped bookmark metadata alongside recents and session stores.
///
/// The schema stores one record per canonical file URL so UI layers can reference
/// a stable identifier without duplicating bookmark blobs across multiple models.
public struct BookmarkPersistenceStore: Sendable {
    public struct Record: Codable, Equatable, Identifiable, Sendable {
        public enum ResolutionState: String, Codable, Equatable, Sendable {
            case unknown
            case succeeded
            case stale
            case failed
        }

        public var id: UUID
        public var canonicalURL: String
        public var bookmarkData: Data
        public var createdAt: Date
        public var updatedAt: Date
        public var lastResolvedAt: Date?
        public var lastResolutionState: ResolutionState

        public var fileURL: URL? {
            URL(string: canonicalURL)
        }
    }

    private struct FileFormat: Codable {
        var version: Int
        var records: [Record]
    }

    private let storageURL: URL
    private let makeDate: @Sendable () -> Date
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        directory: URL,
        fileName: String = "Bookmarks.json",
        makeDate: @escaping @Sendable () -> Date = Date.init
    ) {
        storageURL = directory.appendingPathComponent(fileName, isDirectory: false)
        self.makeDate = makeDate
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    // MARK: - CRUD

    @discardableResult
    public func upsertBookmark(for file: URL, bookmarkData: Data) throws -> Record {
        var index = try loadIndex()
        let canonical = canonicalIdentifier(for: file)
        let now = makeDate()
        if var existing = index[canonical] {
            existing.bookmarkData = bookmarkData
            existing.updatedAt = now
            index[canonical] = existing
        } else {
            let record = Record(
                id: UUID(),
                canonicalURL: canonical,
                bookmarkData: bookmarkData,
                createdAt: now,
                updatedAt: now,
                lastResolvedAt: nil,
                lastResolutionState: .unknown
            )
            index[canonical] = record
        }
        try persist(index)
        return index[canonical]!
    }

    public func record(for file: URL) throws -> Record? {
        let canonical = canonicalIdentifier(for: file)
        let index = try loadIndex()
        return index[canonical]
    }

    public func record(withID id: UUID) throws -> Record? {
        let index = try loadIndex()
        return index.values.first { $0.id == id }
    }

    @discardableResult
    public func markResolution(for file: URL, state: Record.ResolutionState) throws -> Record? {
        var index = try loadIndex()
        let canonical = canonicalIdentifier(for: file)
        guard var existing = index[canonical] else {
            return nil
        }
        let now = makeDate()
        existing.lastResolvedAt = now
        existing.lastResolutionState = state
        existing.updatedAt = now
        index[canonical] = existing
        try persist(index)
        return existing
    }

    public func removeBookmark(for file: URL) throws {
        var index = try loadIndex()
        let canonical = canonicalIdentifier(for: file)
        index.removeValue(forKey: canonical)
        try persist(index)
    }

    public func loadAll() throws -> [Record] {
        let index = try loadIndex()
        return Array(index.values)
    }

    // MARK: - Private helpers

    private func canonicalIdentifier(for file: URL) -> String {
        file.standardizedFileURL.resolvingSymlinksInPath().absoluteString
    }

    private func loadIndex() throws -> [String: Record] {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return [:]
        }
        let data = try Data(contentsOf: storageURL)
        let fileFormat = try decoder.decode(FileFormat.self, from: data)
        return Dictionary(uniqueKeysWithValues: fileFormat.records.map { ($0.canonicalURL, $0) })
    }

    private func persist(_ index: [String: Record]) throws {
        let records = index.values.sorted { lhs, rhs in
            if lhs.canonicalURL == rhs.canonicalURL {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.canonicalURL < rhs.canonicalURL
        }
        let format = FileFormat(version: 1, records: records)
        let data = try encoder.encode(format)
        let directory = storageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: storageURL, options: .atomic)
    }
}
