import Foundation

/// Configuration describing constraints for presenting an open-file dialog.
public struct FilesystemOpenConfiguration: Sendable, Equatable {
    /// Uniform type identifiers allowed by the picker. Represented as type identifier strings
    /// to avoid importing UI-only frameworks inside the core package.
    public var allowedContentTypes: [String]

    /// Whether the picker should allow selecting multiple files at once.
    public var allowsMultipleSelection: Bool

    /// Creates a new configuration.
    /// - Parameters:
    ///   - allowedContentTypes: Uniform type identifiers that the platform dialog should filter by.
    ///   - allowsMultipleSelection: Flag controlling multi-selection behaviour.
    public init(
        allowedContentTypes: [String] = [],
        allowsMultipleSelection: Bool = false
    ) {
        self.allowedContentTypes = allowedContentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
    }
}
