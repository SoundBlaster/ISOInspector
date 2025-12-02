import Foundation

public struct AnnotationRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let nodeID: Int64
    public var note: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), nodeID: Int64, note: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.nodeID = nodeID
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
