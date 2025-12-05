import Foundation

/// Validates track run (trun) boxes in fragmented MP4 files.
///
/// Track runs contain sample metadata for fragments. This rule validates:
/// - Sample count is non-zero
/// - All samples have durations (either per-sample or default)
///
/// Without sample durations, the decode timeline cannot advance and playback will fail.
///
/// ## Rule ID
/// - **VR-017**: Track run validation
///
/// ## Severity
/// - **Error**: Zero sample count or missing sample durations
///
/// ## Example Violations
/// - Track run declares 0 samples
/// - Track run has samples without durations and no default duration set
struct FragmentRunValidationRule: BoxValidationRule {
    func issues(for event: ParseEvent, reader _: RandomAccessReader) -> [ValidationIssue] {
        guard case .willStartBox(let header, _) = event.kind else { return [] }
        guard header.type == BoxType.trackRun else { return [] }
        guard let run = event.payload?.trackRun else { return [] }

        var issues: [ValidationIssue] = []
        let context = contextDescription(for: run)

        if run.sampleCount == 0 {
            let message =
                "Track fragment run\(context) declares 0 samples; ensure track run entries are present."
            issues.append(ValidationIssue(ruleID: "VR-017", message: message, severity: .error))
        }

        let missingDurations = missingDurationEntryIndexes(in: run)
        if !missingDurations.isEmpty {
            let entriesLabel = missingDurations.map(String.init).joined(separator: ", ")
            let message =
                "Track fragment run\(context) is missing sample durations for entries [\(entriesLabel)]; cannot advance decode timeline."
            issues.append(ValidationIssue(ruleID: "VR-017", message: message, severity: .error))
        }

        return issues
    }

    private enum BoxType { static let trackRun = try! FourCharCode("trun") }

    private func contextDescription(for run: ParsedBoxPayload.TrackRunBox) -> String {
        var descriptors: [String] = []
        if let trackID = run.trackID { descriptors.append("track \(trackID)") }
        if let runIndex = run.runIndex { descriptors.append("run #\(runIndex)") }
        if let first = run.firstSampleGlobalIndex {
            if run.sampleCount > 0 {
                let count = UInt64(run.sampleCount)
                if count == 1 {
                    descriptors.append("sample \(first)")
                } else {
                    let (candidate, overflow) = first.addingReportingOverflow(count - 1)
                    if overflow {
                        descriptors.append("sample range starting at \(first)")
                    } else {
                        descriptors.append("samples \(first)-\(candidate)")
                    }
                }
            } else {
                descriptors.append("first sample \(first)")
            }
        }
        guard !descriptors.isEmpty else { return "" }
        return " for " + descriptors.joined(separator: ", ")
    }

    private func missingDurationEntryIndexes(in run: ParsedBoxPayload.TrackRunBox) -> [UInt32] {
        run.entries.compactMap { entry in
            guard entry.sampleDuration == nil else { return nil }
            return entry.index
        }
    }
}
