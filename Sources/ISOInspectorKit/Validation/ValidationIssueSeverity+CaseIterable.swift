import Foundation

extension ValidationIssue.Severity: CaseIterable {
  public static let allCases: [ValidationIssue.Severity] = [.info, .warning, .error]
}
