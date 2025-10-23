import Foundation

/// Shared parser guard rails to keep streaming traversal consistent across
/// ISOInspectorKit, the CLI, and the app targets.
public enum ParserLimits: Sendable {
    /// Maximum allowed nesting depth for container boxes before traversal aborts.
    public static let maximumBoxNestingDepth: Int = 64
}
