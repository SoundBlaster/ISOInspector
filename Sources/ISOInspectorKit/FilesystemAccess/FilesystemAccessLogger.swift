import Foundation

/// Lightweight logging adapter that captures redacted filesystem messages and audit events.
public struct FilesystemAccessLogger: Sendable {
    public var info: @Sendable (String) -> Void
    public var error: @Sendable (String) -> Void
    public let auditTrail: FilesystemAccessAuditTrail
    private let makeDate: @Sendable () -> Date

    public init(
        info: @escaping @Sendable (String) -> Void,
        error: @escaping @Sendable (String) -> Void,
        auditTrail: FilesystemAccessAuditTrail = FilesystemAccessAuditTrail(),
        makeDate: @escaping @Sendable () -> Date
    ) {
        self.info = info
        self.error = error
        self.auditTrail = auditTrail
        self.makeDate = makeDate
    }

    public init(
        _ logger: DiagnosticsLogging,
        auditTrail: FilesystemAccessAuditTrail = FilesystemAccessAuditTrail(),
        makeDate: @escaping @Sendable () -> Date
    ) {
        self.init(
            info: { message in logger.info(message) },
            error: { message in logger.error(message) },
            auditTrail: auditTrail,
            makeDate: makeDate
        )
    }

    public func log(
        category: FilesystemAccessAuditEvent.Category,
        outcome: FilesystemAccessAuditEvent.Outcome,
        pathHash: String? = nil,
        bookmarkIdentifier: UUID? = nil,
        errorDescription: String? = nil
    ) {
        let event = FilesystemAccessAuditEvent(
            timestamp: makeDate(),
            category: category,
            outcome: outcome,
            pathHash: pathHash,
            bookmarkIdentifier: bookmarkIdentifier,
            errorDescription: errorDescription
        )
        auditTrail.append(event)
        let message = event.message
        if outcome.isError {
            error(message)
        } else {
            info(message)
        }
    }

    public static let disabled = FilesystemAccessLogger(
        info: { _ in },
        error: { _ in },
        auditTrail: FilesystemAccessAuditTrail(limit: 0),
        makeDate: {
            Date.init()
        }
    )
}
