import Foundation

extension StructuredPayload {
    struct Issue: Encodable {
        let ruleID: String
        let message: String
        let severity: String
        
        init(issue: ValidationIssue) {
            self.ruleID = issue.ruleID
            self.message = issue.message
            self.severity = issue.severity.rawValue
        }
    }
}
