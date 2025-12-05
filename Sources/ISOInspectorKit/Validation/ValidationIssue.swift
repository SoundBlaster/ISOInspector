import Foundation

public struct ValidationIssue: Equatable, Sendable {
    public enum Severity: String, Equatable, Sendable {
        case info
        case warning
        case error
    }

    public let ruleID: String
    public let message: String
    public let severity: Severity

    public init(ruleID: String, message: String, severity: Severity) {
        self.ruleID = ruleID
        self.message = message
        self.severity = severity
    }
}
