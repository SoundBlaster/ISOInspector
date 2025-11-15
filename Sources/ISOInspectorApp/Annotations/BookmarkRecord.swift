import Foundation

public struct BookmarkRecord: Codable, Equatable, Identifiable, Sendable {
  public var id: Int64 { nodeID }
  public let nodeID: Int64
  public let createdAt: Date

  public init(nodeID: Int64, createdAt: Date) {
    self.nodeID = nodeID
    self.createdAt = createdAt
  }
}
