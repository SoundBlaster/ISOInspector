#if canImport(CoreData)
import CoreData
import Foundation

/// Persists annotations and bookmarks to a CoreData SQLite store keyed by the
/// canonical URL for an inspected media file.
public final class CoreDataAnnotationBookmarkStore: @unchecked Sendable {
    public enum ModelVersion: CaseIterable, Sendable {
        case v1
        case v2

        public static var latest: Self { .v2 }
    }

    private static let containerName = "AnnotationBookmarks"

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    private let makeDate: @Sendable () -> Date

    /// Creates a store backed by a SQLite file inside the provided directory.
    ///
    /// - Parameters:
    ///   - directory: Location that will host the persistent SQLite store.
    ///   - makeDate: Factory returning the current date, primarily injected by
    ///     tests for deterministic timestamps.
    public init(
        directory: URL,
        modelVersion: ModelVersion = .latest,
        makeDate: @escaping @Sendable () -> Date = Date.init
    ) throws {
        self.makeDate = makeDate
        let model = Self.makeModel(for: modelVersion)
        container = NSPersistentContainer(name: Self.containerName, managedObjectModel: model)

        let storeURL = directory.appendingPathComponent("\(Self.containerName).sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            if let error { loadError = error }
        }
        if let loadError {
            throw loadError
        }

        context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Public API

    public func annotations(for file: URL) throws -> [AnnotationRecord] {
        try perform { context in
            guard let fileEntity = try self.fetchFile(for: file, createIfMissing: false, in: context) else {
                return []
            }
            let request = NSFetchRequest<AnnotationEntity>(entityName: "Annotation")
            request.predicate = NSPredicate(format: "file == %@", fileEntity)
            request.sortDescriptors = [NSSortDescriptor(key: #keyPath(AnnotationEntity.createdAt), ascending: true)]
            let entities = try context.fetch(request)
            return entities.map { $0.record }
        }
    }

    public func bookmarks(for file: URL) throws -> [BookmarkRecord] {
        try perform { context in
            guard let fileEntity = try self.fetchFile(for: file, createIfMissing: false, in: context) else {
                return []
            }
            let request = NSFetchRequest<BookmarkEntity>(entityName: "Bookmark")
            request.predicate = NSPredicate(format: "file == %@", fileEntity)
            request.sortDescriptors = [NSSortDescriptor(key: #keyPath(BookmarkEntity.createdAt), ascending: true)]
            let entities = try context.fetch(request)
            return entities.map { $0.record }
        }
    }

    @discardableResult
    public func createAnnotation(for file: URL, nodeID: Int64, note: String) throws -> AnnotationRecord {
        try perform { context in
            let fileEntity = try self.fetchFile(for: file, createIfMissing: true, in: context)!
            let now = self.makeDate()
            let annotation = AnnotationEntity(context: context)
            annotation.id = UUID()
            annotation.nodeID = nodeID
            annotation.note = note
            annotation.createdAt = now
            annotation.updatedAt = now
            annotation.file = fileEntity
            fileEntity.touch(at: now)
            try context.saveIfNeeded()
            return annotation.record
        }
    }

    @discardableResult
    public func updateAnnotation(for file: URL, annotationID: UUID, note: String) throws -> AnnotationRecord {
        try perform { context in
            guard let fileEntity = try self.fetchFile(for: file, createIfMissing: false, in: context),
                  let annotation = try self.fetchAnnotation(id: annotationID, for: fileEntity, in: context) else {
                throw AnnotationBookmarkStoreError.annotationNotFound
            }
            let now = self.makeDate()
            annotation.note = note
            annotation.updatedAt = now
            fileEntity.touch(at: now)
            try context.saveIfNeeded()
            return annotation.record
        }
    }

    public func deleteAnnotation(for file: URL, annotationID: UUID) throws {
        try perform { context in
            guard let fileEntity = try self.fetchFile(for: file, createIfMissing: false, in: context),
                  let annotation = try self.fetchAnnotation(id: annotationID, for: fileEntity, in: context) else {
                throw AnnotationBookmarkStoreError.annotationNotFound
            }
            context.delete(annotation)
            let now = self.makeDate()
            fileEntity.touch(at: now)
            try context.saveIfNeeded()
        }
    }

    public func setBookmark(for file: URL, nodeID: Int64, isBookmarked: Bool) throws {
        try perform { context in
            guard let fileEntity = try self.fetchFile(for: file, createIfMissing: isBookmarked, in: context) else {
                return
            }

            var didModify = false
            let now = self.makeDate()

            if isBookmarked {
                let existing = try self.fetchBookmark(nodeID: nodeID, for: fileEntity, in: context)
                if existing == nil {
                    let bookmark = BookmarkEntity(context: context)
                    bookmark.id = UUID()
                    bookmark.nodeID = nodeID
                    bookmark.createdAt = now
                    bookmark.file = fileEntity
                    didModify = true
                }
            } else if let existing = try self.fetchBookmark(nodeID: nodeID, for: fileEntity, in: context) {
                context.delete(existing)
                didModify = true
            }

            if didModify {
                fileEntity.touch(at: now)
                try context.saveIfNeeded()
            }
        }
    }

    // MARK: - Session Persistence

    public func loadCurrentSession() throws -> WorkspaceSessionSnapshot? {
        try perform { context in
            guard let session = try self.fetchCurrentSession(in: context) else {
                return nil
            }
            return session.makeSnapshot()
        }
    }

    public func saveCurrentSession(_ snapshot: WorkspaceSessionSnapshot) throws {
        try perform { context in
            let workspace = try self.fetchOrCreateWorkspace(in: context)
            if let appVersion = snapshot.appVersion {
                workspace.appVersion = appVersion
            }
            workspace.lastOpened = snapshot.updatedAt
            workspace.schemaVersion = 2

            let session = try self.fetchOrCreateSession(id: snapshot.id, in: context, workspace: workspace)
            session.createdAt = snapshot.createdAt
            session.updatedAt = snapshot.updatedAt
            session.lastSceneIdentifier = snapshot.lastSceneIdentifier
            session.isCurrent = true
            session.focusedFileURL = snapshot.focusedFileURL?.absoluteString

            try self.markOtherSessionsInactive(excluding: session, in: context)
            try self.replaceSessionFiles(for: session, with: snapshot.files, in: context)
            try self.replaceWindowLayouts(for: session, with: snapshot.windowLayouts, in: context)

            try context.saveIfNeeded()
        }
    }

    public func clearCurrentSession() throws {
        try perform { context in
            let request = NSFetchRequest<SessionEntity>(entityName: "Session")
            request.predicate = NSPredicate(format: "isCurrent == YES")
            let sessions = try context.fetch(request)
            guard !sessions.isEmpty else { return }
            for session in sessions {
                session.isCurrent = false
                session.focusedFileURL = nil
                session.lastSceneIdentifier = nil
                if let files = session.files as? Set<SessionFileEntity> {
                    for file in files {
                        context.delete(file)
                    }
                }
                if let layouts = session.layouts as? Set<WindowLayoutEntity> {
                    for layout in layouts {
                        context.delete(layout)
                    }
                }
            }
            try context.saveIfNeeded()
        }
    }

    // MARK: - Private helpers

    private func perform<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        var value: T?
        var capturedError: Error?
        context.performAndWait {
            do {
                value = try block(context)
            } catch {
                capturedError = error
            }
        }
        if let capturedError {
            throw capturedError
        }
        guard let value else {
            throw CocoaError(.coderReadCorrupt)
        }
        return value
    }

    private func fetchFile(
        for file: URL,
        createIfMissing: Bool,
        in context: NSManagedObjectContext
    ) throws -> FileEntity? {
        let identifier = canonicalIdentifier(for: file)
        let request = NSFetchRequest<FileEntity>(entityName: "File")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "url == %@", identifier)
        if let existing = try context.fetch(request).first {
            return existing
        }
        guard createIfMissing else {
            return nil
        }
        let fileEntity = FileEntity(context: context)
        fileEntity.id = UUID()
        fileEntity.url = identifier
        let now = makeDate()
        fileEntity.createdAt = now
        fileEntity.updatedAt = now
        return fileEntity
    }

    private func fetchAnnotation(
        id: UUID,
        for file: FileEntity,
        in context: NSManagedObjectContext
    ) throws -> AnnotationEntity? {
        let request = NSFetchRequest<AnnotationEntity>(entityName: "Annotation")
        request.fetchLimit = 1
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "id == %@", id as CVarArg),
            NSPredicate(format: "file == %@", file)
        ])
        return try context.fetch(request).first
    }

    private func fetchBookmark(
        nodeID: Int64,
        for file: FileEntity,
        in context: NSManagedObjectContext
    ) throws -> BookmarkEntity? {
        let request = NSFetchRequest<BookmarkEntity>(entityName: "Bookmark")
        request.fetchLimit = 1
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "nodeID == %lld", nodeID),
            NSPredicate(format: "file == %@", file)
        ])
        return try context.fetch(request).first
    }

    private func fetchBookmark(
        id: UUID,
        for file: FileEntity,
        in context: NSManagedObjectContext
    ) throws -> BookmarkEntity? {
        let request = NSFetchRequest<BookmarkEntity>(entityName: "Bookmark")
        request.fetchLimit = 1
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "id == %@", id as CVarArg),
            NSPredicate(format: "file == %@", file)
        ])
        return try context.fetch(request).first
    }

    private func canonicalIdentifier(for file: URL) -> String {
        file.standardizedFileURL.resolvingSymlinksInPath().absoluteString
    }

    private func fetchCurrentSession(in context: NSManagedObjectContext) throws -> SessionEntity? {
        let request = NSFetchRequest<SessionEntity>(entityName: "Session")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "isCurrent == YES")
        request.relationshipKeyPathsForPrefetching = [
            "workspace",
            "files",
            "files.file",
            "files.bookmarkDiffs",
            "layouts"
        ]
        return try context.fetch(request).first
    }

    private func fetchOrCreateWorkspace(in context: NSManagedObjectContext) throws -> WorkspaceEntity {
        let request = NSFetchRequest<WorkspaceEntity>(entityName: "Workspace")
        request.fetchLimit = 1
        if let existing = try context.fetch(request).first {
            return existing
        }
        let workspace = WorkspaceEntity(context: context)
        workspace.id = UUID()
        workspace.appVersion = ""
        workspace.lastOpened = makeDate()
        workspace.schemaVersion = 2
        return workspace
    }

    private func fetchOrCreateSession(
        id: UUID,
        in context: NSManagedObjectContext,
        workspace: WorkspaceEntity
    ) throws -> SessionEntity {
        let request = NSFetchRequest<SessionEntity>(entityName: "Session")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let existing = try context.fetch(request).first {
            existing.workspace = workspace
            return existing
        }
        let session = SessionEntity(context: context)
        session.id = id
        session.createdAt = makeDate()
        session.updatedAt = makeDate()
        session.workspace = workspace
        return session
    }

    private func markOtherSessionsInactive(
        excluding activeSession: SessionEntity,
        in context: NSManagedObjectContext
    ) throws {
        let request = NSFetchRequest<SessionEntity>(entityName: "Session")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isCurrent == YES"),
            NSPredicate(format: "self != %@", activeSession)
        ])
        let sessions = try context.fetch(request)
        for session in sessions {
            session.isCurrent = false
        }
    }

    private func replaceSessionFiles(
        for session: SessionEntity,
        with snapshots: [WorkspaceSessionFileSnapshot],
        in context: NSManagedObjectContext
    ) throws {
        if let existing = session.files as? Set<SessionFileEntity> {
            for file in existing {
                context.delete(file)
            }
        }

        let orderedSnapshots = snapshots.sorted { lhs, rhs in
            if lhs.orderIndex == rhs.orderIndex {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.orderIndex < rhs.orderIndex
        }

        for snapshot in orderedSnapshots {
            guard let fileEntity = try fetchFile(for: snapshot.recent.url, createIfMissing: true, in: context) else {
                continue
            }

            let sessionFile = SessionFileEntity(context: context)
            sessionFile.id = snapshot.id
            sessionFile.orderIndex = Int64(snapshot.orderIndex)
            if let selection = snapshot.lastSelectionNodeID {
                sessionFile.lastSelectionNodeID = NSNumber(value: selection)
            } else {
                sessionFile.lastSelectionNodeID = nil
            }
            if let offset = snapshot.scrollOffset {
                sessionFile.scrollOffsetX = NSNumber(value: offset.x)
                sessionFile.scrollOffsetY = NSNumber(value: offset.y)
            } else {
                sessionFile.scrollOffsetX = nil
                sessionFile.scrollOffsetY = nil
            }
            sessionFile.isPinned = snapshot.isPinned
            sessionFile.displayName = snapshot.recent.displayName
            sessionFile.lastOpened = snapshot.recent.lastOpened
            sessionFile.bookmarkData = snapshot.recent.bookmarkData
            sessionFile.bookmarkIdentifier = snapshot.bookmarkIdentifier ?? snapshot.recent.bookmarkIdentifier
            sessionFile.session = session
            sessionFile.file = fileEntity

            for diff in snapshot.bookmarkDiffs {
                let diffEntity = SessionBookmarkDiffEntity(context: context)
                diffEntity.id = diff.id
                diffEntity.bookmarkID = diff.bookmarkID
                diffEntity.isRemoved = diff.isRemoved
                diffEntity.noteDelta = diff.noteDelta
                diffEntity.sessionFile = sessionFile
                if let bookmarkID = diff.bookmarkID,
                   let bookmark = try self.fetchBookmark(id: bookmarkID, for: fileEntity, in: context) {
                    diffEntity.bookmark = bookmark
                    diffEntity.bookmarkID = bookmarkID
                } else {
                    diffEntity.bookmark = nil
                }
            }
        }
    }

    private func replaceWindowLayouts(
        for session: SessionEntity,
        with layouts: [WorkspaceWindowLayoutSnapshot],
        in context: NSManagedObjectContext
    ) {
        if let existing = session.layouts as? Set<WindowLayoutEntity> {
            for layout in existing {
                context.delete(layout)
            }
        }

        for snapshot in layouts {
            let layout = WindowLayoutEntity(context: context)
            layout.id = snapshot.id
            layout.sceneIdentifier = snapshot.sceneIdentifier
            layout.serializedLayout = snapshot.serializedLayout
            layout.isFloatingInspector = snapshot.isFloatingInspector
            layout.session = session
        }
    }
}

#if canImport(Combine)
extension CoreDataAnnotationBookmarkStore: AnnotationBookmarkStoring {}
#endif

extension CoreDataAnnotationBookmarkStore: WorkspaceSessionStoring {}

// MARK: - CoreData Model

private extension CoreDataAnnotationBookmarkStore {
    static func makeModel(for version: ModelVersion) -> NSManagedObjectModel {
        switch version {
        case .v1:
            return makeV1Model()
        case .v2:
            return makeV2Model()
        }
    }

    struct BaseEntities {
        let file: NSEntityDescription
        let annotation: NSEntityDescription
        let bookmark: NSEntityDescription
    }

    static func makeBaseEntities() -> BaseEntities {
        let fileEntity = NSEntityDescription()
        fileEntity.name = "File"
        fileEntity.managedObjectClassName = NSStringFromClass(FileEntity.self)

        let fileID = uuidAttribute(named: "id")
        let fileURL = stringAttribute(named: "url")
        let fileCreated = dateAttribute(named: "createdAt")
        let fileUpdated = dateAttribute(named: "updatedAt")

        let annotationEntity = NSEntityDescription()
        annotationEntity.name = "Annotation"
        annotationEntity.managedObjectClassName = NSStringFromClass(AnnotationEntity.self)

        let annotationID = uuidAttribute(named: "id")
        let annotationNodeID = int64Attribute(named: "nodeID")
        let annotationNote = stringAttribute(named: "note")
        let annotationCreated = dateAttribute(named: "createdAt")
        let annotationUpdated = dateAttribute(named: "updatedAt")

        let bookmarkEntity = NSEntityDescription()
        bookmarkEntity.name = "Bookmark"
        bookmarkEntity.managedObjectClassName = NSStringFromClass(BookmarkEntity.self)

        let bookmarkID = uuidAttribute(named: "id")
        let bookmarkNodeID = int64Attribute(named: "nodeID")
        let bookmarkCreated = dateAttribute(named: "createdAt")

        let fileToAnnotations = NSRelationshipDescription()
        fileToAnnotations.name = "annotations"
        fileToAnnotations.destinationEntity = annotationEntity
        fileToAnnotations.minCount = 0
        fileToAnnotations.maxCount = 0
        fileToAnnotations.deleteRule = .cascadeDeleteRule
        fileToAnnotations.isOrdered = false

        let annotationsToFile = NSRelationshipDescription()
        annotationsToFile.name = "file"
        annotationsToFile.destinationEntity = fileEntity
        annotationsToFile.minCount = 1
        annotationsToFile.maxCount = 1
        annotationsToFile.deleteRule = .nullifyDeleteRule
        annotationsToFile.isOrdered = false

        let fileToBookmarks = NSRelationshipDescription()
        fileToBookmarks.name = "bookmarks"
        fileToBookmarks.destinationEntity = bookmarkEntity
        fileToBookmarks.minCount = 0
        fileToBookmarks.maxCount = 0
        fileToBookmarks.deleteRule = .cascadeDeleteRule
        fileToBookmarks.isOrdered = false

        let bookmarksToFile = NSRelationshipDescription()
        bookmarksToFile.name = "file"
        bookmarksToFile.destinationEntity = fileEntity
        bookmarksToFile.minCount = 1
        bookmarksToFile.maxCount = 1
        bookmarksToFile.deleteRule = .nullifyDeleteRule
        bookmarksToFile.isOrdered = false

        fileToAnnotations.inverseRelationship = annotationsToFile
        annotationsToFile.inverseRelationship = fileToAnnotations

        fileToBookmarks.inverseRelationship = bookmarksToFile
        bookmarksToFile.inverseRelationship = fileToBookmarks

        fileEntity.properties = [fileID, fileURL, fileCreated, fileUpdated, fileToAnnotations, fileToBookmarks]
        annotationEntity.properties = [annotationID, annotationNodeID, annotationNote, annotationCreated, annotationUpdated, annotationsToFile]
        bookmarkEntity.properties = [bookmarkID, bookmarkNodeID, bookmarkCreated, bookmarksToFile]

        return BaseEntities(file: fileEntity, annotation: annotationEntity, bookmark: bookmarkEntity)
    }

    static func makeV1Model() -> NSManagedObjectModel {
        let base = makeBaseEntities()
        let model = NSManagedObjectModel()
        model.entities = [base.file, base.annotation, base.bookmark]
        return model
    }

    static func makeV2Model() -> NSManagedObjectModel {
        let base = makeBaseEntities()
        let fileEntity = base.file
        let annotationEntity = base.annotation
        let bookmarkEntity = base.bookmark

        let workspaceEntity = NSEntityDescription()
        workspaceEntity.name = "Workspace"
        workspaceEntity.managedObjectClassName = NSStringFromClass(WorkspaceEntity.self)

        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "Session"
        sessionEntity.managedObjectClassName = NSStringFromClass(SessionEntity.self)

        let sessionFileEntity = NSEntityDescription()
        sessionFileEntity.name = "SessionFile"
        sessionFileEntity.managedObjectClassName = NSStringFromClass(SessionFileEntity.self)

        let windowLayoutEntity = NSEntityDescription()
        windowLayoutEntity.name = "WindowLayout"
        windowLayoutEntity.managedObjectClassName = NSStringFromClass(WindowLayoutEntity.self)

        let sessionBookmarkDiffEntity = NSEntityDescription()
        sessionBookmarkDiffEntity.name = "SessionBookmarkDiff"
        sessionBookmarkDiffEntity.managedObjectClassName = NSStringFromClass(SessionBookmarkDiffEntity.self)

        // Workspace attributes
        let workspaceID = uuidAttribute(named: "id")
        let workspaceAppVersion = stringAttribute(named: "appVersion", isOptional: true)
        let workspaceLastOpened = dateAttribute(named: "lastOpened")
        let workspaceSchemaVersion = int64Attribute(named: "schemaVersion")

        // Session attributes
        let sessionID = uuidAttribute(named: "id")
        let sessionCreatedAt = dateAttribute(named: "createdAt")
        let sessionUpdatedAt = dateAttribute(named: "updatedAt")
        let sessionLastSceneIdentifier = stringAttribute(named: "lastSceneIdentifier", isOptional: true)
        let sessionIsCurrent = boolAttribute(named: "isCurrent")
        let sessionFocusedFileURL = stringAttribute(named: "focusedFileURL", isOptional: true)

        // SessionFile attributes
        let sessionFileID = uuidAttribute(named: "id")
        let sessionFileOrderIndex = int64Attribute(named: "orderIndex")
        let sessionFileLastSelectionNodeID = int64Attribute(named: "lastSelectionNodeID", isOptional: true)
        let sessionFileScrollOffsetX = doubleAttribute(named: "scrollOffsetX", isOptional: true)
        let sessionFileScrollOffsetY = doubleAttribute(named: "scrollOffsetY", isOptional: true)
        let sessionFileIsPinned = boolAttribute(named: "isPinned")
        let sessionFileDisplayName = stringAttribute(named: "displayName")
        let sessionFileLastOpened = dateAttribute(named: "lastOpened")
        let sessionFileBookmarkData = binaryAttribute(named: "bookmarkData", isOptional: true)
        let sessionFileBookmarkIdentifier = uuidAttribute(named: "bookmarkIdentifier", isOptional: true)

        // WindowLayout attributes
        let windowLayoutID = uuidAttribute(named: "id")
        let windowLayoutSceneIdentifier = stringAttribute(named: "sceneIdentifier")
        let windowLayoutSerializedLayout = binaryAttribute(named: "serializedLayout")
        let windowLayoutIsFloatingInspector = boolAttribute(named: "isFloatingInspector")

        // SessionBookmarkDiff attributes
        let sessionBookmarkDiffID = uuidAttribute(named: "id")
        let sessionBookmarkDiffBookmarkID = uuidAttribute(named: "bookmarkID", isOptional: true)
        let sessionBookmarkDiffIsRemoved = boolAttribute(named: "isRemoved")
        let sessionBookmarkDiffNoteDelta = stringAttribute(named: "noteDelta", isOptional: true)

        // Relationships
        let workspaceToSessions = NSRelationshipDescription()
        workspaceToSessions.name = "sessions"
        workspaceToSessions.destinationEntity = sessionEntity
        workspaceToSessions.minCount = 0
        workspaceToSessions.maxCount = 0
        workspaceToSessions.deleteRule = .cascadeDeleteRule
        workspaceToSessions.isOrdered = false

        let sessionsToWorkspace = NSRelationshipDescription()
        sessionsToWorkspace.name = "workspace"
        sessionsToWorkspace.destinationEntity = workspaceEntity
        sessionsToWorkspace.minCount = 1
        sessionsToWorkspace.maxCount = 1
        sessionsToWorkspace.deleteRule = .nullifyDeleteRule
        sessionsToWorkspace.isOrdered = false

        let sessionToFiles = NSRelationshipDescription()
        sessionToFiles.name = "files"
        sessionToFiles.destinationEntity = sessionFileEntity
        sessionToFiles.minCount = 0
        sessionToFiles.maxCount = 0
        sessionToFiles.deleteRule = .cascadeDeleteRule
        sessionToFiles.isOrdered = false

        let sessionFileToSession = NSRelationshipDescription()
        sessionFileToSession.name = "session"
        sessionFileToSession.destinationEntity = sessionEntity
        sessionFileToSession.minCount = 1
        sessionFileToSession.maxCount = 1
        sessionFileToSession.deleteRule = .nullifyDeleteRule
        sessionFileToSession.isOrdered = false

        let sessionToLayouts = NSRelationshipDescription()
        sessionToLayouts.name = "layouts"
        sessionToLayouts.destinationEntity = windowLayoutEntity
        sessionToLayouts.minCount = 0
        sessionToLayouts.maxCount = 0
        sessionToLayouts.deleteRule = .cascadeDeleteRule
        sessionToLayouts.isOrdered = false

        let windowLayoutToSession = NSRelationshipDescription()
        windowLayoutToSession.name = "session"
        windowLayoutToSession.destinationEntity = sessionEntity
        windowLayoutToSession.minCount = 1
        windowLayoutToSession.maxCount = 1
        windowLayoutToSession.deleteRule = .nullifyDeleteRule
        windowLayoutToSession.isOrdered = false

        let sessionFileToBookmarkDiffs = NSRelationshipDescription()
        sessionFileToBookmarkDiffs.name = "bookmarkDiffs"
        sessionFileToBookmarkDiffs.destinationEntity = sessionBookmarkDiffEntity
        sessionFileToBookmarkDiffs.minCount = 0
        sessionFileToBookmarkDiffs.maxCount = 0
        sessionFileToBookmarkDiffs.deleteRule = .cascadeDeleteRule
        sessionFileToBookmarkDiffs.isOrdered = false

        let sessionBookmarkDiffToSessionFile = NSRelationshipDescription()
        sessionBookmarkDiffToSessionFile.name = "sessionFile"
        sessionBookmarkDiffToSessionFile.destinationEntity = sessionFileEntity
        sessionBookmarkDiffToSessionFile.minCount = 1
        sessionBookmarkDiffToSessionFile.maxCount = 1
        sessionBookmarkDiffToSessionFile.deleteRule = .nullifyDeleteRule
        sessionBookmarkDiffToSessionFile.isOrdered = false

        let sessionBookmarkDiffToBookmark = NSRelationshipDescription()
        sessionBookmarkDiffToBookmark.name = "bookmark"
        sessionBookmarkDiffToBookmark.destinationEntity = bookmarkEntity
        sessionBookmarkDiffToBookmark.minCount = 0
        sessionBookmarkDiffToBookmark.maxCount = 1
        sessionBookmarkDiffToBookmark.deleteRule = .nullifyDeleteRule
        sessionBookmarkDiffToBookmark.isOrdered = false

        let bookmarkToDiffs = NSRelationshipDescription()
        bookmarkToDiffs.name = "sessionDiffs"
        bookmarkToDiffs.destinationEntity = sessionBookmarkDiffEntity
        bookmarkToDiffs.minCount = 0
        bookmarkToDiffs.maxCount = 0
        bookmarkToDiffs.deleteRule = .nullifyDeleteRule
        bookmarkToDiffs.isOrdered = false

        let sessionFileToFile = NSRelationshipDescription()
        sessionFileToFile.name = "file"
        sessionFileToFile.destinationEntity = fileEntity
        sessionFileToFile.minCount = 1
        sessionFileToFile.maxCount = 1
        sessionFileToFile.deleteRule = .nullifyDeleteRule
        sessionFileToFile.isOrdered = false

        let fileToSessionFiles = NSRelationshipDescription()
        fileToSessionFiles.name = "sessionFiles"
        fileToSessionFiles.destinationEntity = sessionFileEntity
        fileToSessionFiles.minCount = 0
        fileToSessionFiles.maxCount = 0
        fileToSessionFiles.deleteRule = .cascadeDeleteRule
        fileToSessionFiles.isOrdered = false

        // Inverses
        workspaceToSessions.inverseRelationship = sessionsToWorkspace
        sessionsToWorkspace.inverseRelationship = workspaceToSessions

        sessionToFiles.inverseRelationship = sessionFileToSession
        sessionFileToSession.inverseRelationship = sessionToFiles

        sessionToLayouts.inverseRelationship = windowLayoutToSession
        windowLayoutToSession.inverseRelationship = sessionToLayouts

        sessionFileToBookmarkDiffs.inverseRelationship = sessionBookmarkDiffToSessionFile
        sessionBookmarkDiffToSessionFile.inverseRelationship = sessionFileToBookmarkDiffs

        sessionBookmarkDiffToBookmark.inverseRelationship = bookmarkToDiffs
        bookmarkToDiffs.inverseRelationship = sessionBookmarkDiffToBookmark

        fileToSessionFiles.inverseRelationship = sessionFileToFile
        sessionFileToFile.inverseRelationship = fileToSessionFiles

        workspaceEntity.properties = [workspaceID, workspaceAppVersion, workspaceLastOpened, workspaceSchemaVersion, workspaceToSessions]

        sessionEntity.properties = [
            sessionID,
            sessionCreatedAt,
            sessionUpdatedAt,
            sessionLastSceneIdentifier,
            sessionIsCurrent,
            sessionFocusedFileURL,
            sessionsToWorkspace,
            sessionToFiles,
            sessionToLayouts
        ]

        var fileProperties = fileEntity.properties
        fileProperties.append(fileToSessionFiles)
        fileEntity.properties = fileProperties

        var bookmarkProperties = bookmarkEntity.properties
        bookmarkProperties.append(bookmarkToDiffs)
        bookmarkEntity.properties = bookmarkProperties

        sessionFileEntity.properties = [
            sessionFileID,
            sessionFileOrderIndex,
            sessionFileLastSelectionNodeID,
            sessionFileScrollOffsetX,
            sessionFileScrollOffsetY,
            sessionFileIsPinned,
            sessionFileDisplayName,
            sessionFileLastOpened,
            sessionFileBookmarkData,
            sessionFileBookmarkIdentifier,
            sessionFileToSession,
            sessionFileToFile,
            sessionFileToBookmarkDiffs
        ]

        windowLayoutEntity.properties = [
            windowLayoutID,
            windowLayoutSceneIdentifier,
            windowLayoutSerializedLayout,
            windowLayoutIsFloatingInspector,
            windowLayoutToSession
        ]

        sessionBookmarkDiffEntity.properties = [
            sessionBookmarkDiffID,
            sessionBookmarkDiffBookmarkID,
            sessionBookmarkDiffIsRemoved,
            sessionBookmarkDiffNoteDelta,
            sessionBookmarkDiffToSessionFile,
            sessionBookmarkDiffToBookmark
        ]

        let model = NSManagedObjectModel()
        model.entities = [
            fileEntity,
            annotationEntity,
            bookmarkEntity,
            workspaceEntity,
            sessionEntity,
            sessionFileEntity,
            windowLayoutEntity,
            sessionBookmarkDiffEntity
        ]
        return model
    }

    static func uuidAttribute(named name: String, isOptional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .UUIDAttributeType
        attribute.isOptional = isOptional
        return attribute
    }

    static func stringAttribute(named name: String, isOptional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .stringAttributeType
        attribute.isOptional = isOptional
        return attribute
    }

    static func dateAttribute(named name: String, isOptional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .dateAttributeType
        attribute.isOptional = isOptional
        return attribute
    }

    static func int64Attribute(named name: String, isOptional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .integer64AttributeType
        attribute.isOptional = isOptional
        return attribute
    }

    static func doubleAttribute(named name: String, isOptional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .doubleAttributeType
        attribute.isOptional = isOptional
        return attribute
    }

    static func binaryAttribute(named name: String, isOptional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .binaryDataAttributeType
        attribute.isOptional = isOptional
        return attribute
    }

    static func boolAttribute(named name: String) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .booleanAttributeType
        attribute.isOptional = false
        return attribute
    }
}

// MARK: - Managed Object subclasses

@objc(FileEntity)
private final class FileEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var url: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var sessionFiles: NSSet?

    func touch(at date: Date) {
        updatedAt = date
    }
}

@objc(AnnotationEntity)
private final class AnnotationEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var nodeID: Int64
    @NSManaged var note: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var file: FileEntity

    var record: AnnotationRecord {
        AnnotationRecord(id: id, nodeID: nodeID, note: note, createdAt: createdAt, updatedAt: updatedAt)
    }
}

@objc(BookmarkEntity)
private final class BookmarkEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var nodeID: Int64
    @NSManaged var createdAt: Date
    @NSManaged var file: FileEntity
    @NSManaged var sessionDiffs: NSSet?

    var record: BookmarkRecord {
        BookmarkRecord(nodeID: nodeID, createdAt: createdAt)
    }
}

@objc(WorkspaceEntity)
private final class WorkspaceEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var appVersion: String
    @NSManaged var lastOpened: Date
    @NSManaged var schemaVersion: Int64
    @NSManaged var sessions: NSSet?
}

@objc(SessionEntity)
private final class SessionEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var lastSceneIdentifier: String?
    @NSManaged var isCurrent: Bool
    @NSManaged var focusedFileURL: String?
    @NSManaged var workspace: WorkspaceEntity
    @NSManaged var files: NSSet?
    @NSManaged var layouts: NSSet?
}

@objc(SessionFileEntity)
private final class SessionFileEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var orderIndex: Int64
    @NSManaged var lastSelectionNodeID: NSNumber?
    @NSManaged var scrollOffsetX: NSNumber?
    @NSManaged var scrollOffsetY: NSNumber?
    @NSManaged var isPinned: Bool
    @NSManaged var displayName: String
    @NSManaged var lastOpened: Date
    @NSManaged var bookmarkData: Data?
    @NSManaged var bookmarkIdentifier: UUID?
    @NSManaged var session: SessionEntity
    @NSManaged var file: FileEntity
    @NSManaged var bookmarkDiffs: NSSet?
}

@objc(WindowLayoutEntity)
private final class WindowLayoutEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var sceneIdentifier: String
    @NSManaged var serializedLayout: Data
    @NSManaged var isFloatingInspector: Bool
    @NSManaged var session: SessionEntity
}

@objc(SessionBookmarkDiffEntity)
private final class SessionBookmarkDiffEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var bookmarkID: UUID?
    @NSManaged var isRemoved: Bool
    @NSManaged var noteDelta: String?
    @NSManaged var sessionFile: SessionFileEntity
    @NSManaged var bookmark: BookmarkEntity?
}

private extension SessionEntity {
    func makeSnapshot() -> WorkspaceSessionSnapshot {
        let fileSnapshots = (files as? Set<SessionFileEntity>)?
            .compactMap { $0.makeSnapshot() }
            .sorted { lhs, rhs in
                if lhs.orderIndex == rhs.orderIndex {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.orderIndex < rhs.orderIndex
            } ?? []

        let layoutSnapshots = (layouts as? Set<WindowLayoutEntity>)?
            .map { $0.makeSnapshot() }
            .sorted { lhs, rhs in lhs.sceneIdentifier < rhs.sceneIdentifier } ?? []

        let focusedURL = focusedFileURL.flatMap { URL(string: $0) }
        let version = workspace.appVersion.isEmpty ? nil : workspace.appVersion

        return WorkspaceSessionSnapshot(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            appVersion: version,
            files: fileSnapshots,
            focusedFileURL: focusedURL,
            lastSceneIdentifier: lastSceneIdentifier,
            windowLayouts: layoutSnapshots
        )
    }
}

private extension SessionFileEntity {
    func makeSnapshot() -> WorkspaceSessionFileSnapshot? {
        guard let url = URL(string: file.url) else { return nil }
        let recent = DocumentRecent(
            url: url,
            bookmarkIdentifier: bookmarkIdentifier,
            bookmarkData: bookmarkData,
            displayName: displayName,
            lastOpened: lastOpened
        )

        let selection = lastSelectionNodeID?.int64Value
        let scrollOffset: WorkspaceSessionScrollOffset?
        if let x = scrollOffsetX?.doubleValue, let y = scrollOffsetY?.doubleValue {
            scrollOffset = WorkspaceSessionScrollOffset(x: x, y: y)
        } else {
            scrollOffset = nil
        }

        let diffs = (bookmarkDiffs as? Set<SessionBookmarkDiffEntity>)?
            .map { $0.makeSnapshot() }
            .sorted { $0.id.uuidString < $1.id.uuidString } ?? []

        return WorkspaceSessionFileSnapshot(
            id: id,
            recent: recent,
            orderIndex: Int(orderIndex),
            lastSelectionNodeID: selection,
            isPinned: isPinned,
            scrollOffset: scrollOffset,
            bookmarkIdentifier: bookmarkIdentifier ?? recent.bookmarkIdentifier,
            bookmarkDiffs: diffs
        )
    }
}

private extension SessionBookmarkDiffEntity {
    func makeSnapshot() -> WorkspaceSessionBookmarkDiff {
        let identifier = bookmarkID ?? bookmark?.id
        WorkspaceSessionBookmarkDiff(
            id: id,
            bookmarkID: identifier,
            isRemoved: isRemoved,
            noteDelta: noteDelta
        )
    }
}

private extension WindowLayoutEntity {
    func makeSnapshot() -> WorkspaceWindowLayoutSnapshot {
        WorkspaceWindowLayoutSnapshot(
            id: id,
            sceneIdentifier: sceneIdentifier,
            serializedLayout: serializedLayout,
            isFloatingInspector: isFloatingInspector
        )
    }
}

private extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        if hasChanges {
            try save()
        }
    }
}
#else
import Foundation

/// Placeholder implementation compiled on platforms that do not ship CoreData
/// (e.g., Linux CI environments). The concrete CoreData-backed implementation
/// is only available when the framework is present.
public final class CoreDataAnnotationBookmarkStore: @unchecked Sendable {
    public enum ModelVersion: CaseIterable, Sendable {
        case v1
        case v2

        public static var latest: Self { .v2 }
    }

    public init(
        directory: URL,
        modelVersion: ModelVersion = .latest,
        makeDate: @escaping @Sendable () -> Date = Date.init
    ) throws {
        _ = (directory, modelVersion, makeDate)
        throw CocoaError(.featureUnsupported)
    }

    public func annotations(for file: URL) throws -> [AnnotationRecord] {
        _ = file
        return []
    }

    public func bookmarks(for file: URL) throws -> [BookmarkRecord] {
        _ = file
        return []
    }

    @discardableResult
    public func createAnnotation(for file: URL, nodeID: Int64, note: String) throws -> AnnotationRecord {
        throw CocoaError(.featureUnsupported)
    }

    @discardableResult
    public func updateAnnotation(for file: URL, annotationID: UUID, note: String) throws -> AnnotationRecord {
        throw CocoaError(.featureUnsupported)
    }

    public func deleteAnnotation(for file: URL, annotationID: UUID) throws {
        throw CocoaError(.featureUnsupported)
    }

    public func setBookmark(for file: URL, nodeID: Int64, isBookmarked: Bool) throws {
        throw CocoaError(.featureUnsupported)
    }

    public func loadCurrentSession() throws -> WorkspaceSessionSnapshot? {
        return nil
    }

    public func saveCurrentSession(_ snapshot: WorkspaceSessionSnapshot) throws {
        _ = snapshot
        throw CocoaError(.featureUnsupported)
    }

    public func clearCurrentSession() throws {
        throw CocoaError(.featureUnsupported)
    }
}
#endif
