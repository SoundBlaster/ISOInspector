import Foundation

/// Abstraction over creating and resolving bookmark data.
public protocol BookmarkDataManaging: Sendable {
  /// Creates bookmark data for the given URL.
  func createBookmark(for url: URL) throws -> Data

  /// Resolves bookmark data, returning the resolved URL and whether the bookmark is stale.
  func resolveBookmark(data: Data) throws -> BookmarkResolution
}
