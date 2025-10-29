#if canImport(Combine) && canImport(SwiftUI)
    import Combine
    import Foundation
    import ISOInspectorKit
    @testable import ISOInspectorApp

    typealias BookmarkResolutionState = BookmarkPersistenceStore.Record.ResolutionState

    final class DocumentRecentsStoreStub: DocumentRecentsStoring {
        var initialRecents: [DocumentRecent]
        private(set) var savedRecents: [DocumentRecent]?
        var saveHandler: (([DocumentRecent]) throws -> Void)?

        init(initialRecents: [DocumentRecent]) {
            self.initialRecents = initialRecents
        }

        func load() throws -> [DocumentRecent] {
            initialRecents
        }

        func save(_ recents: [DocumentRecent]) throws {
            savedRecents = recents
            if let saveHandler {
                try saveHandler(recents)
            }
        }
    }

    final class ValidationConfigurationStoreStub: ValidationConfigurationPersisting {
        var storedConfiguration: ValidationConfiguration?
        var loadError: Error?
        private(set) var savedConfigurations: [ValidationConfiguration] = []
        private(set) var clearedCount = 0

        func loadConfiguration() throws -> ValidationConfiguration? {
            if let loadError {
                throw loadError
            }
            return storedConfiguration
        }

        func saveConfiguration(_ configuration: ValidationConfiguration) throws {
            savedConfigurations.append(configuration)
            storedConfiguration = configuration
        }

        func clearConfiguration() throws {
            clearedCount += 1
            storedConfiguration = nil
        }
    }

    final class BookmarkPersistenceStoreStub: BookmarkPersistenceManaging, @unchecked Sendable {
        private struct StoredRecord {
            var record: BookmarkPersistenceStore.Record
        }

        private(set) var upsertedURLs: [URL] = []
        private(set) var markedResolutions: [(URL, BookmarkResolutionState)] = []
        private(set) var removedURLs: [URL] = []

        var canonicalize: (URL) -> String = { url in
            url.standardizedFileURL.resolvingSymlinksInPath().absoluteString
        }

        var dateProvider: () -> Date = Date.init

        private var storage: [String: StoredRecord] = [:]

        func record(for file: URL) throws -> BookmarkPersistenceStore.Record? {
            storage[canonicalize(file)]?.record
        }

        func record(withID id: UUID) throws -> BookmarkPersistenceStore.Record? {
            storage.values.first { $0.record.id == id }?.record
        }

        @discardableResult
        func upsertBookmark(for file: URL, bookmarkData: Data) throws
            -> BookmarkPersistenceStore.Record {
            let canonical = canonicalize(file)
            upsertedURLs.append(file)
            if var existing = storage[canonical]?.record {
                existing.bookmarkData = bookmarkData
                existing.updatedAt = dateProvider()
                storage[canonical] = StoredRecord(record: existing)
                return existing
            }
            let record = BookmarkPersistenceStore.Record(
                id: UUID(),
                canonicalURL: canonical,
                bookmarkData: bookmarkData,
                createdAt: dateProvider(),
                updatedAt: dateProvider(),
                lastResolvedAt: nil,
                lastResolutionState: .unknown
            )
            storage[canonical] = StoredRecord(record: record)
            return record
        }

        @discardableResult
        func markResolution(for file: URL, state: BookmarkResolutionState) throws
            -> BookmarkPersistenceStore.Record? {
            let canonical = canonicalize(file)
            markedResolutions.append((file, state))
            guard var stored = storage[canonical]?.record else {
                return nil
            }
            stored.lastResolutionState = state
            stored.lastResolvedAt = dateProvider()
            storage[canonical] = StoredRecord(record: stored)
            return stored
        }

        func removeBookmark(for file: URL) throws {
            removedURLs.append(file)
            storage.removeValue(forKey: canonicalize(file))
        }

        func resetTracking() {
            upsertedURLs.removeAll()
            markedResolutions.removeAll()
            removedURLs.removeAll()
        }
    }

    final class WorkspaceSessionStoreStub: WorkspaceSessionStoring, @unchecked Sendable {
        var loadedSnapshot: WorkspaceSessionSnapshot?
        private(set) var savedSnapshots: [WorkspaceSessionSnapshot] = []
        private(set) var clearCallCount = 0
        var saveHandler: ((WorkspaceSessionSnapshot) throws -> Void)?
        var clearHandler: (() throws -> Void)?

        func loadCurrentSession() throws -> WorkspaceSessionSnapshot? {
            loadedSnapshot
        }

        func saveCurrentSession(_ snapshot: WorkspaceSessionSnapshot) throws {
            savedSnapshots.append(snapshot)
            if let saveHandler {
                try saveHandler(snapshot)
            }
        }

        func clearCurrentSession() throws {
            clearCallCount += 1
            if let clearHandler {
                try clearHandler()
            }
        }
    }

    final class DiagnosticsLoggerStub: DiagnosticsLogging {
        private(set) var infos: [String] = []
        private(set) var errors: [String] = []

        func info(_ message: String) {
            infos.append(message)
        }

        func error(_ message: String) {
            errors.append(message)
        }
    }

    extension DiagnosticsLoggerStub: @unchecked Sendable {}

    final class AnnotationBookmarkStoreStub: AnnotationBookmarkStoring {
        func annotations(for file: URL) throws -> [AnnotationRecord] { [] }

        func bookmarks(for file: URL) throws -> [BookmarkRecord] { [] }

        func createAnnotation(for file: URL, nodeID: Int64, note: String) throws -> AnnotationRecord {
            AnnotationRecord(
                id: UUID(), nodeID: nodeID, note: note, createdAt: Date(), updatedAt: Date())
        }

        func updateAnnotation(for file: URL, annotationID: UUID, note: String) throws
            -> AnnotationRecord {
            AnnotationRecord(
                id: annotationID, nodeID: nodeIDPlaceholder, note: note, createdAt: Date(),
                updatedAt: Date())
        }

        func deleteAnnotation(for file: URL, annotationID: UUID) throws {}

        func setBookmark(for file: URL, nodeID: Int64, isBookmarked: Bool) throws {}

        private var nodeIDPlaceholder: Int64 { 0 }
    }

    struct ImmediateWorkQueue: DocumentSessionWorkQueue {
        func execute(_ work: @escaping () -> Void) {
            work()
            if Thread.isMainThread {
                RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
            }
        }
    }

    extension ParsePipeline.EventStream {
        static var finishedStream: ParsePipeline.EventStream {
            AsyncThrowingStream { continuation in
                continuation.finish()
            }
        }
    }

    final class StubRandomAccessReader: RandomAccessReader {
        let length: Int64 = 0

        func read(at offset: Int64, count: Int) throws -> Data {
            Data(count: count)
        }
    }

    final class SecurityScopedAccessManagerStub: SecurityScopedAccessManaging {
        var allowAccess = true
        private(set) var startedURLs: [URL] = []
        private(set) var stoppedURLs: [URL] = []

        func startAccessing(_ url: URL) -> Bool {
            startedURLs.append(url.standardizedFileURL)
            return allowAccess
        }

        func stopAccessing(_ url: URL) {
            stoppedURLs.append(url.standardizedFileURL)
        }
    }

    extension SecurityScopedAccessManagerStub: @unchecked Sendable {}

    final class FilesystemAccessStub: @unchecked Sendable {
        let manager = SecurityScopedAccessManagerStub()
        var resolutions: [Data: BookmarkResolution] = [:]
        var resolutionError: Error?
        var bookmarkCreator: ((URL) throws -> Data)?
        var saveHandler: (@Sendable (FilesystemSaveConfiguration) async throws -> URL)?
        private(set) var lastSaveConfiguration: FilesystemSaveConfiguration?
        private(set) var lastSavedURL: URL?

        func makeAccess() -> FilesystemAccess {
            FilesystemAccess(
                openFileHandler: { _ in URL(fileURLWithPath: "/tmp/stub-open.mp4") },
                saveFileHandler: { [weak self] configuration in
                    guard let self else { return URL(fileURLWithPath: "/tmp/stub-save.mp4") }
                    self.lastSaveConfiguration = configuration
                    let destination: URL
                    if let handler = self.saveHandler {
                        destination = try await handler(configuration)
                    } else {
                        destination = URL(fileURLWithPath: "/tmp/stub-save.mp4")
                    }
                    self.lastSavedURL = destination
                    return destination
                },
                bookmarkCreator: { [weak self] url in
                    if let creator = self?.bookmarkCreator {
                        return try creator(url)
                    }
                    return Data(url.path.utf8)
                },
                bookmarkResolver: { [weak self] data in
                    if let error = self?.resolutionError {
                        throw error
                    }
                    if let resolution = self?.resolutions[data] {
                        return resolution
                    }
                    let path = String(decoding: data, as: UTF8.self)
                    return BookmarkResolution(url: URL(fileURLWithPath: path), isStale: false)
                },
                securityScopeManager: manager,
                logger: .disabled
            )
        }
    }
#endif
