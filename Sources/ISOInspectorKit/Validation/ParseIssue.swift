import Foundation

/// Represents a recoverable parsing problem that can be surfaced to callers
/// while allowing the pipeline to continue processing additional boxes.
///
/// `ParseIssue` mirrors the upcoming tolerant parsing mode requirements by
/// recording the severity, reason code, diagnostic message, and byte range for
/// each corruption event. The `affectedNodeIDs` collection references the
/// nodes that surfaced the issue so that clients can highlight or navigate to
/// them.
public struct ParseIssue: Equatable, Sendable, Codable {
  public enum Severity: String, Equatable, Sendable, Codable {
    case info
    case warning
    case error
  }

  public let severity: Severity
  public let code: String
  public let message: String
  public let byteRange: Range<Int64>?
  public let affectedNodeIDs: [Int64]

  public init(
    severity: Severity,
    code: String,
    message: String,
    byteRange: Range<Int64>? = nil,
    affectedNodeIDs: [Int64] = []
  ) {
    self.severity = severity
    self.code = code
    self.message = message
    self.byteRange = byteRange
    self.affectedNodeIDs = affectedNodeIDs
  }
}

extension ParseIssue.Severity: CaseIterable {}
