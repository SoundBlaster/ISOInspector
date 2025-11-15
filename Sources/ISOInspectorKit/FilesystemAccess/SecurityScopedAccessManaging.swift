import Foundation

/// Abstraction over starting and stopping access to security-scoped resources.
public protocol SecurityScopedAccessManaging: Sendable {
  /// Attempts to activate the security scope for the provided URL.
  /// - Parameter url: The file URL the caller wants to access.
  /// - Returns: A boolean indicating whether the scope was successfully activated.
  func startAccessing(_ url: URL) -> Bool

  /// Ends access to the provided URL.
  /// - Parameter url: The URL whose scope should be released.
  func stopAccessing(_ url: URL)
}
