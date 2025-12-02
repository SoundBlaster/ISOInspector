import Foundation

/// Validates that the file type box (ftyp) appears before media boxes.
///
/// ISO/IEC 14496-12 requires the file type box (ftyp) to appear before any media-related
/// boxes (moov, trak, mdia, moof, mdat, etc.). This allows parsers to:
/// - Identify the file format and brand
/// - Select appropriate parsing strategies
/// - Reject unsupported file types early
///
/// ## Rule ID
/// - **VR-004**: File type ordering
///
/// ## Severity
/// - **Error**: Media box before ftyp
///
/// ## Example Violations
/// - moov box appears at offset 0 before ftyp
/// - mdat box encountered before ftyp
final class FileTypeOrderingRule: BoxValidationRule, @unchecked Sendable {
    private var hasSeenFileType = false

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case .willStartBox(let header, _) = event.kind else { return [] }

        let type = header.type.rawValue
        if type == "ftyp" {
            hasSeenFileType = true
            return []
        }

        guard !hasSeenFileType, Self.mediaBoxTypes.contains(type) else { return [] }

        let message = "Encountered \(header.identifierString) before required file type box (ftyp)."
        return [ValidationIssue(ruleID: "VR-004", message: message, severity: .error)]
    }

    private static let mediaBoxTypes: Set<String> = {
        var values: Set<String> = [
            FourCharContainerCode.moov.rawValue, FourCharContainerCode.trak.rawValue,
            FourCharContainerCode.mdia.rawValue, FourCharContainerCode.minf.rawValue,
            FourCharContainerCode.stbl.rawValue, FourCharContainerCode.moof.rawValue,
            FourCharContainerCode.traf.rawValue, FourCharContainerCode.mvex.rawValue,
        ]
        values.formUnion(MediaAndIndexBoxCode.rawValueSet)
        return values
    }()
}
