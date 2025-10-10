import Foundation

public struct AnnotationBookmarkSession: Codable, Equatable, Sendable {
    public var annotations: [AnnotationRecord]
    public var bookmarks: [BookmarkRecord]

    public init(
        annotations: [AnnotationRecord] = [],
        bookmarks: [BookmarkRecord] = []
    ) {
        self.annotations = annotations
        self.bookmarks = bookmarks
    }
}
