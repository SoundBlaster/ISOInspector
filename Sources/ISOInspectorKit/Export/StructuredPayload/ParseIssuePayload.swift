import Foundation

extension StructuredPayload {
    struct ParseIssuePayload: Encodable {
        let severity: String
        let code: String
        let message: String
        let byteRange: ByteRange?
        let affectedNodeIDs: [Int64]
        
        init(issue: ParseIssue) {
            self.severity = issue.severity.rawValue
            self.code = issue.code
            self.message = issue.message
            if let range = issue.byteRange {
                self.byteRange = ByteRange(range: range)
            } else {
                self.byteRange = nil
            }
            self.affectedNodeIDs = issue.affectedNodeIDs
        }
    }
}
