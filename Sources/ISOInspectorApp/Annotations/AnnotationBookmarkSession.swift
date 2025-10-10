#if canImport(Combine)
import Combine
import Foundation

protocol AnnotationBookmarkStoring: Sendable {
    func annotations(for file: URL) throws -> [AnnotationRecord]
    func bookmarks(for file: URL) throws -> [BookmarkRecord]
    func createAnnotation(for file: URL, nodeID: Int64, note: String) throws -> AnnotationRecord
    func updateAnnotation(for file: URL, annotationID: UUID, note: String) throws -> AnnotationRecord
    func deleteAnnotation(for file: URL, annotationID: UUID) throws
    func setBookmark(for file: URL, nodeID: Int64, isBookmarked: Bool) throws
}

@MainActor
final class AnnotationBookmarkSession: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var activeAnnotations: [AnnotationRecord] = []
    @Published private(set) var isSelectedNodeBookmarked: Bool = false
    @Published private(set) var bookmarks: Set<Int64> = []
    @Published private(set) var lastErrorMessage: String?

    private let store: AnnotationBookmarkStoring?
    let isStoreAvailable: Bool
    private var fileURL: URL?
    private var annotationsByNode: [Int64: [AnnotationRecord]] = [:]
    private var selectedNodeID: Int64?

    init(store: AnnotationBookmarkStoring?) {
        self.store = store
        self.isStoreAvailable = store != nil
        self.isEnabled = store != nil
    }

    func setFileURL(_ file: URL?) {
        if fileURL == file { return }
        fileURL = file?.standardizedFileURL

        guard let store else {
            isEnabled = false
            annotationsByNode = [:]
            bookmarks = []
            activeAnnotations = []
            isSelectedNodeBookmarked = false
            lastErrorMessage = nil
            return
        }

        guard let fileURL else {
            isEnabled = false
            annotationsByNode = [:]
            bookmarks = []
            activeAnnotations = []
            isSelectedNodeBookmarked = false
            selectedNodeID = nil
            lastErrorMessage = nil
            return
        }

        do {
            let annotations = try store.annotations(for: fileURL)
            annotationsByNode = Dictionary(grouping: annotations, by: { $0.nodeID }).mapValues { records in
                records.sorted(by: sortAnnotationsByCreation)
            }
            let bookmarkRecords = try store.bookmarks(for: fileURL)
            bookmarks = Set(bookmarkRecords.map(\.nodeID))
            isEnabled = true
            lastErrorMessage = nil
        } catch {
            annotationsByNode = [:]
            bookmarks = []
            isEnabled = false
            lastErrorMessage = error.localizedDescription
        }

        refreshActiveState()
    }

    func setSelectedNode(_ nodeID: Int64?) {
        selectedNodeID = nodeID
        refreshActiveState()
    }

    func addAnnotation(note: String) {
        guard let store, let fileURL, let nodeID = selectedNodeID else { return }

        do {
            let record = try store.createAnnotation(for: fileURL, nodeID: nodeID, note: note)
            annotationsByNode[nodeID, default: []].append(record)
            annotationsByNode[nodeID]?.sort(by: sortAnnotationsByCreation)
            lastErrorMessage = nil
            refreshActiveState()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func updateAnnotation(id: UUID, note: String) {
        guard let store, let fileURL, let nodeID = selectedNodeID else { return }
        do {
            let record = try store.updateAnnotation(for: fileURL, annotationID: id, note: note)
            if var records = annotationsByNode[nodeID], let index = records.firstIndex(where: { $0.id == id }) {
                records[index] = record
                records.sort(by: sortAnnotationsByCreation)
                annotationsByNode[nodeID] = records
            } else {
                annotationsByNode[nodeID, default: []].append(record)
                annotationsByNode[nodeID]?.sort(by: sortAnnotationsByCreation)
            }
            lastErrorMessage = nil
            refreshActiveState()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func deleteAnnotation(id: UUID) {
        guard let store, let fileURL, let nodeID = selectedNodeID else { return }
        do {
            try store.deleteAnnotation(for: fileURL, annotationID: id)
            if var records = annotationsByNode[nodeID] {
                records.removeAll { $0.id == id }
                annotationsByNode[nodeID] = records
            }
            lastErrorMessage = nil
            refreshActiveState()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func toggleBookmark() {
        guard let store, let fileURL, let nodeID = selectedNodeID else { return }
        let shouldBookmark = !bookmarks.contains(nodeID)
        do {
            try store.setBookmark(for: fileURL, nodeID: nodeID, isBookmarked: shouldBookmark)
            if shouldBookmark {
                bookmarks.insert(nodeID)
            } else {
                bookmarks.remove(nodeID)
            }
            lastErrorMessage = nil
            refreshActiveState()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func isBookmarked(nodeID: Int64) -> Bool {
        bookmarks.contains(nodeID)
    }

    private func refreshActiveState() {
        if let nodeID = selectedNodeID {
            activeAnnotations = annotationsByNode[nodeID] ?? []
            isSelectedNodeBookmarked = bookmarks.contains(nodeID)
        } else {
            activeAnnotations = []
            isSelectedNodeBookmarked = false
        }
    }

}

private func sortAnnotationsByCreation(_ lhs: AnnotationRecord, _ rhs: AnnotationRecord) -> Bool {
    if lhs.createdAt == rhs.createdAt {
        return lhs.id.uuidString < rhs.id.uuidString
    }
    return lhs.createdAt < rhs.createdAt
}
#endif
