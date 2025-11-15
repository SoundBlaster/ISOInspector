import Foundation

/// Result of resolving previously stored bookmark data.
public struct BookmarkResolution: Sendable, Equatable {
  /// The resolved file URL.
  public let url: URL

  /// Indicates whether the bookmark data was marked stale during resolution.
  public let isStale: Bool

  public init(url: URL, isStale: Bool) {
    self.url = url
    self.isStale = isStale
  }
}
