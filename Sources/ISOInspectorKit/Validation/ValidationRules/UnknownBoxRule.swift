import Foundation

/// Reports unknown box types for catalog research.
///
/// This informational rule identifies boxes that are not recognized by the parser's
/// box descriptor registry. Unknown boxes may indicate:
/// - Proprietary or vendor-specific extensions
/// - New box types from updated specifications
/// - Malformed FourCC codes
///
/// ## Rule ID
/// - **VR-006**: Unknown box type
///
/// ## Severity
/// - **Info**: Unknown box encountered
///
/// ## Example Violations
/// - Box with FourCC "abcd" has no registered descriptor
/// - Custom UUID box without metadata entry
struct UnknownBoxRule: BoxValidationRule {
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case .willStartBox(let header, _) = event.kind else { return [] }
        guard event.metadata == nil else { return [] }
        return [
            ValidationIssue(
                ruleID: "VR-006",
                message:
                    "Unknown box type \(header.identifierString) encountered; schedule catalog research.",
                severity: .info)
        ]
    }
}
