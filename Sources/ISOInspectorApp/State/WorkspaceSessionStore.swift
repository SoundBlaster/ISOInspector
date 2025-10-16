#if canImport(Foundation)
import Foundation

public struct WorkspaceSessionSnapshot: Codable, Equatable, Sendable {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var appVersion: String?
    var files: [WorkspaceSessionFileSnapshot]
    var focusedFileURL: URL?
    var lastSceneIdentifier: String?
    var windowLayouts: [WorkspaceWindowLayoutSnapshot]
}

public struct WorkspaceSessionFileSnapshot: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    var recent: DocumentRecent
    var orderIndex: Int
    var lastSelectionNodeID: Int64?
    var isPinned: Bool
    var scrollOffset: WorkspaceSessionScrollOffset?
    var bookmarkIdentifier: UUID?
    var bookmarkDiffs: [WorkspaceSessionBookmarkDiff]
}

public struct WorkspaceSessionScrollOffset: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
}

public struct WorkspaceWindowLayoutSnapshot: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    var sceneIdentifier: String
    var serializedLayout: Data
    var isFloatingInspector: Bool
}

public struct WorkspaceSessionBookmarkDiff: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    var bookmarkID: UUID?
    var isRemoved: Bool
    var noteDelta: String?
}

public protocol WorkspaceSessionStoring: Sendable {
    func loadCurrentSession() throws -> WorkspaceSessionSnapshot?
    func saveCurrentSession(_ snapshot: WorkspaceSessionSnapshot) throws
    func clearCurrentSession() throws
}

public struct FileBackedWorkspaceSessionStore: WorkspaceSessionStoring {
    private let storageURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directory: URL, fileName: String = "WorkspaceSession.json") {
        self.storageURL = directory.appendingPathComponent(fileName, isDirectory: false)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    public func loadCurrentSession() throws -> WorkspaceSessionSnapshot? {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: storageURL)
        return try decoder.decode(WorkspaceSessionSnapshot.self, from: data)
    }

    public func saveCurrentSession(_ snapshot: WorkspaceSessionSnapshot) throws {
        let data = try encoder.encode(snapshot)
        let directory = storageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: storageURL, options: .atomic)
    }

    public func clearCurrentSession() throws {
        if FileManager.default.fileExists(atPath: storageURL.path) {
            try FileManager.default.removeItem(at: storageURL)
        }
    }
}
#endif
