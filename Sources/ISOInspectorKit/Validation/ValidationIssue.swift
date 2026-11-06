import Foundation

public struct ValidationIssue: Equatable, Sendable {
    public enum Location: Equatable, Sendable {
        case box
        case bytes(Range<Int64>)
    }

    public enum Severity: String, Equatable, Sendable {
        case info
        case warning
        case error
    }

    public let ruleID: String
    public let message: String
    public let severity: Severity
    public let location: Location

    public init(ruleID: String, message: String, severity: Severity, location: Location = .box) {
        self.ruleID = ruleID
        self.message = message
        self.severity = severity
        self.location = location
    }
}
