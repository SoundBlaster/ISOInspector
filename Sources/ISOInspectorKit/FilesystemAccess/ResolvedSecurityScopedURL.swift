import Foundation

/// Represents a resolved bookmark along with its active security scope.
public struct ResolvedSecurityScopedURL: Sendable, Equatable {
  public let url: SecurityScopedURL
  public let isStale: Bool

  public init(url: SecurityScopedURL, isStale: Bool) {
    self.url = url
    self.isStale = isStale
  }
}
