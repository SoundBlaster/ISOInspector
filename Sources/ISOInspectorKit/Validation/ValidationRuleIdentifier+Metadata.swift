import Foundation

extension ValidationRuleIdentifier {
    public var displayName: String {
        switch self {
        case .structuralSize: return "Box Size Integrity"
        case .containerBoundary: return "Container Boundary Closure"
        case .versionFlags: return "Version and Flags Consistency"
        case .fileTypeOrdering: return "File Type Ordering"
        case .movieDataOrdering: return "Movie Data Ordering"
        case .researchLogRecording: return "Research Log Recording"
        case .editListDuration: return "Edit List Duration Reconciliation"
        case .sampleTableCorrelation: return "Sample Table Correlation"
        case .fragmentSequence: return "Fragment Sequence Order"
        case .fragmentRun: return "Fragment Run Integrity"
        case .codecConfiguration: return "Codec Configuration Integrity"
        }
    }

    public var summary: String {
        switch self {
        case .structuralSize:
            return "Ensures declared sizes cover headers and remain within file bounds."
        case .containerBoundary:
            return "Checks containers open and close at the exact declared offsets."
        case .versionFlags:
            return "Compares version and flag fields against MP4RA catalog metadata."
        case .fileTypeOrdering: return "Requires the ftyp box to appear before any media container."
        case .movieDataOrdering:
            return "Ensures moov precedes mdat unless streaming indicators allow otherwise."
        case .researchLogRecording:
            return "Captures unknown box types for follow-up research logging."
        case .editListDuration:
            return "Reconciles edit list spans with movie, track, and media durations."
        case .sampleTableCorrelation:
            return "Validates chunk, size, and timing tables describe the same sample counts."
        case .fragmentSequence:
            return
                "Flags non-monotonic fragment identifiers or unexpected gaps in sequence numbers."
        case .fragmentRun:
            return "Ensures fragment runs reference valid sample counts and byte ranges."
        case .codecConfiguration:
            return "Validates avcC and hvcC parameter set declarations and payload lengths."
        }
    }

    public var defaultSeverity: ValidationIssue.Severity {
        switch self {
        case .structuralSize, .containerBoundary, .fileTypeOrdering, .sampleTableCorrelation,
            .fragmentRun, .codecConfiguration:
            return .error
        case .versionFlags, .movieDataOrdering, .editListDuration, .fragmentSequence:
            return .warning
        case .researchLogRecording: return .info
        }
    }
}
