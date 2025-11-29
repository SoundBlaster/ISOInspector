import Foundation

extension Array where Element == ParseIssue {
    func containsGuardIssues() -> Bool {
        contains { $0.code.hasPrefix("guard.") }
    }
}
