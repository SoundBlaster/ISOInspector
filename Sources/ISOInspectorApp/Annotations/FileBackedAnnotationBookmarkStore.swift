import Foundation

/// The store performs synchronous file I/O using immutable collaborators, so it is
/// safe to treat as sendable even though ``FileManager`` itself does not conform to
/// ``Sendable``.
public final class FileBackedAnnotationBookmarkStore: @unchecked Sendable {
    private let directory: URL
    private let fileManager: FileManager
    private let makeDate: @Sendable () -> Date
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        directory: URL,
        fileManager: FileManager = .default,
        makeDate: @escaping @Sendable () -> Date = Date.init
    ) {
        self.directory = directory
        self.fileManager = fileManager
        self.makeDate = makeDate
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    public func annotations(for file: URL) throws -> [AnnotationRecord] {
        try loadSession(for: file).annotations
    }

    public func bookmarks(for file: URL) throws -> [BookmarkRecord] {
        try loadSession(for: file).bookmarks
    }

    @discardableResult
    public func createAnnotation(for file: URL, nodeID: Int64, note: String) throws -> AnnotationRecord {
        var session = try loadSession(for: file)
        let now = makeDate()
        let record = AnnotationRecord(nodeID: nodeID, note: note, createdAt: now, updatedAt: now)
        session.annotations.append(record)
        try persist(session, for: file)
        return record
    }

    @discardableResult
    public func updateAnnotation(for file: URL, annotationID: UUID, note: String) throws -> AnnotationRecord {
        var session = try loadSession(for: file)
        guard let index = session.annotations.firstIndex(where: { $0.id == annotationID }) else {
            throw AnnotationBookmarkStoreError.annotationNotFound
        }
        session.annotations[index].note = note
        session.annotations[index].updatedAt = makeDate()
        try persist(session, for: file)
        return session.annotations[index]
    }

    public func deleteAnnotation(for file: URL, annotationID: UUID) throws {
        var session = try loadSession(for: file)
        let originalCount = session.annotations.count
        session.annotations.removeAll { $0.id == annotationID }
        guard session.annotations.count != originalCount else {
            throw AnnotationBookmarkStoreError.annotationNotFound
        }
        try persist(session, for: file)
    }

    public func setBookmark(for file: URL, nodeID: Int64, isBookmarked: Bool) throws {
        var session = try loadSession(for: file)
        if isBookmarked {
            if !session.bookmarks.contains(where: { $0.nodeID == nodeID }) {
                session.bookmarks.append(BookmarkRecord(nodeID: nodeID, createdAt: makeDate()))
            }
        } else {
            session.bookmarks.removeAll { $0.nodeID == nodeID }
        }
        try persist(session, for: file)
    }

    // MARK: - Private

    private func loadSession(for file: URL) throws -> AnnotationBookmarkSession {
        let url = try storageURL(for: file)
        guard fileManager.fileExists(atPath: url.path) else {
            return AnnotationBookmarkSession()
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(AnnotationBookmarkSession.self, from: data)
    }

    private func persist(_ session: AnnotationBookmarkSession, for file: URL) throws {
        let url = try storageURL(for: file)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let data = try encoder.encode(session)
        try data.write(to: url, options: [.atomic])
    }

    private func storageURL(for file: URL) throws -> URL {
        let identifier = try identifierForFile(file)
        return directory.appendingPathComponent("\(identifier).json")
    }

    private func identifierForFile(_ file: URL) throws -> String {
        guard let data = file.standardizedFileURL.path.data(using: .utf8) else {
            throw CocoaError(.fileReadUnknownStringEncoding)
        }
        let encoded = data.base64EncodedString()
        return encoded
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "+", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// @todo #10 Replace JSON persistence with the selected CoreData schema once R6 finalizes the storage decision. Link these records to session metadata for multi-file support.
