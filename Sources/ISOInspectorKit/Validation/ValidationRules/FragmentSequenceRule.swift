import Foundation

/// Validates movie fragment sequence numbers for fragmented MP4 files.
///
/// Fragmented MP4 files (CMAF, DASH, HLS fMP4) contain movie fragments (moof) with
/// movie fragment headers (mfhd) that declare sequence numbers. This rule validates:
/// - Sequence numbers start at 1 (not 0)
/// - Sequence numbers are strictly monotonic (always increasing)
///
/// ## Rule ID
/// - **VR-016**: Fragment sequence validation
///
/// ## Severity
/// - **Warning**: Zero sequence number or non-monotonic sequence
///
/// ## Example Violations
/// - Fragment header declares sequence number 0 (should start at 1)
/// - Fragment #2 has sequence 5, fragment #3 has sequence 3 (non-monotonic)
/// - Two consecutive fragments both declare sequence 10
final class FragmentSequenceRule: BoxValidationRule, @unchecked Sendable {
    private var lastSequenceNumber: UInt32?
    private var lastHeader: BoxHeader?

    func issues(for event: ParseEvent, reader _: RandomAccessReader) -> [ValidationIssue] {
        guard case .willStartBox(let header, _) = event.kind else { return [] }
        guard header.type == BoxType.movieFragmentHeader else { return [] }
        guard let fragment = event.payload?.movieFragmentHeader else { return [] }

        var issues: [ValidationIssue] = []

        if fragment.sequenceNumber == 0 {
            let message =
                "\(header.identifierString) sequence number is zero; fragments should start at 1."
            issues.append(ValidationIssue(ruleID: "VR-016", message: message, severity: .warning))
        }

        if let previous = lastSequenceNumber, fragment.sequenceNumber <= previous {
            let previousLabel = lastHeader?.identifierString ?? "previous fragment"
            let message =
                "\(header.identifierString) has non-monotonic sequence number \(fragment.sequenceNumber) (previous \(previousLabel) used \(previous))."
            issues.append(ValidationIssue(ruleID: "VR-016", message: message, severity: .warning))
        }

        lastSequenceNumber = fragment.sequenceNumber
        lastHeader = header
        return issues
    }

    private enum BoxType { static let movieFragmentHeader = try! FourCharCode("mfhd") }
}
