import Foundation

/// Validates that box size declarations are structurally valid.
///
/// Checks:
/// - Total size is not smaller than header size
/// - Box does not extend beyond file length
///
/// Rule ID: VR-001
struct StructuralSizeRule: BoxValidationRule {
  func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
    guard case .willStartBox(let header, _) = event.kind else { return [] }

    var issues: [ValidationIssue] = []
    if header.totalSize < header.headerSize {
      let message =
        "Box \(header.identifierString) declares total size \(header.totalSize) smaller than header length \(header.headerSize)."
      issues.append(ValidationIssue(ruleID: "VR-001", message: message, severity: .error))
    }

    if header.endOffset > reader.length {
      let message =
        "Box \(header.identifierString) extends beyond file length (declared end \(header.endOffset), file length \(reader.length))."
      issues.append(ValidationIssue(ruleID: "VR-001", message: message, severity: .error))
    }

    return issues
  }
}
