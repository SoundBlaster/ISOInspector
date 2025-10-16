import Foundation

/// Lightweight logging adapter that captures redacted filesystem messages.
public struct FilesystemAccessLogger: Sendable {
    public var info: @Sendable (String) -> Void
    public var error: @Sendable (String) -> Void

    public init(
        info: @escaping @Sendable (String) -> Void,
        error: @escaping @Sendable (String) -> Void
    ) {
        self.info = info
        self.error = error
    }

    public init(_ logger: DiagnosticsLogging) {
        self.init(
            info: { message in logger.info(message) },
            error: { message in logger.error(message) }
        )
    }

    public static let disabled = FilesystemAccessLogger(info: { _ in }, error: { _ in })
}
