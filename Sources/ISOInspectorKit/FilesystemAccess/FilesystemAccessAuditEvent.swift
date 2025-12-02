import Foundation

public struct FilesystemAccessAuditEvent: Equatable, Sendable {
    public enum Category: String, Sendable {
        case openFile = "open_file"
        case saveFile = "save_file"
        case bookmarkCreate = "bookmark.create"
        case bookmarkResolve = "bookmark.resolve"
        case externalGrant = "scope.external_grant"
    }

    public enum Outcome: String, Sendable {
        case accessGranted = "access_granted"
        case authorizationDenied = "authorization_denied"
        case success
        case failure
        case stale

        var isError: Bool {
            switch self {
            case .accessGranted, .success: return false
            case .authorizationDenied, .failure, .stale: return true
            }
        }
    }

    public var timestamp: Date
    public var category: Category
    public var outcome: Outcome
    public var pathHash: String?
    public var bookmarkIdentifier: UUID?
    public var errorDescription: String?

    public init(
        timestamp: Date, category: Category, outcome: Outcome, pathHash: String?,
        bookmarkIdentifier: UUID?, errorDescription: String?
    ) {
        self.timestamp = timestamp
        self.category = category
        self.outcome = outcome
        self.pathHash = pathHash
        self.bookmarkIdentifier = bookmarkIdentifier
        self.errorDescription = errorDescription
    }

    public var message: String {
        var components: [String] = ["\(category.rawValue).\(outcome.rawValue)"]
        if let pathHash { components.append("path_hash=\(pathHash)") }
        if let bookmarkIdentifier {
            components.append("bookmark_id=\(bookmarkIdentifier.uuidString)")
        }
        if let errorDescription { components.append("error=\(errorDescription)") }
        components.append("timestamp=\(FilesystemAccessAuditEvent.formatTimestamp(timestamp))")
        return components.joined(separator: " ")
    }
}

extension FilesystemAccessAuditEvent {
    fileprivate static func formatTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
