#if canImport(CoreData)
import CoreData
import Foundation

/// Persists annotations and bookmarks to a CoreData SQLite store keyed by the
/// canonical URL for an inspected media file.
public final class CoreDataAnnotationBookmarkStore: @unchecked Sendable {
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
        makeDate: @escaping @Sendable () -> Date = Date.init
    ) throws {
        self.makeDate = makeDate
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "AnnotationBookmarks", managedObjectModel: model)

        let storeURL = directory.appendingPathComponent("AnnotationBookmarks.sqlite")
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
        let mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        context.performAndWait {
            context.mergePolicy = mergePolicy
            context.automaticallyMergesChangesFromParent = true
        }
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

    private func canonicalIdentifier(for file: URL) -> String {
        file.standardizedFileURL.resolvingSymlinksInPath().absoluteString
    }
}

// MARK: - CoreData Model

private extension CoreDataAnnotationBookmarkStore {
    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

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

        model.entities = [fileEntity, annotationEntity, bookmarkEntity]
        return model
    }

    static func uuidAttribute(named name: String) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .UUIDAttributeType
        attribute.isOptional = false
        return attribute
    }

    static func stringAttribute(named name: String) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .stringAttributeType
        attribute.isOptional = false
        return attribute
    }

    static func dateAttribute(named name: String) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .dateAttributeType
        attribute.isOptional = false
        return attribute
    }

    static func int64Attribute(named name: String) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .integer64AttributeType
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

    var record: BookmarkRecord {
        BookmarkRecord(nodeID: nodeID, createdAt: createdAt)
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
    public init(
        directory: URL,
        makeDate: @escaping @Sendable () -> Date = Date.init
    ) throws {
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
}
#endif
