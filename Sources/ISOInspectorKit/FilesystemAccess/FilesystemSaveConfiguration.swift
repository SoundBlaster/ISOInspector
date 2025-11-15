import Foundation

/// Configuration describing constraints for presenting a save-file dialog.
public struct FilesystemSaveConfiguration: Sendable, Equatable {
  /// Uniform type identifiers allowed by the picker, represented as strings.
  public var allowedContentTypes: [String]

  /// Suggested filename that the platform dialog should pre-populate.
  public var suggestedFilename: String?

  /// Creates a new configuration.
  /// - Parameters:
  ///   - allowedContentTypes: Uniform type identifiers allowed by the save dialog.
  ///   - suggestedFilename: Optional filename suggestion.
  public init(
    allowedContentTypes: [String] = [],
    suggestedFilename: String? = nil
  ) {
    self.allowedContentTypes = allowedContentTypes
    self.suggestedFilename = suggestedFilename
  }
}
