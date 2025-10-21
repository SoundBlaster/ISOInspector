import Foundation
import ISOInspectorKit

public struct EventConsoleFormatter: Sendable {
    public init() {}

    public func format(_ event: ParseEvent) -> String {
        var segments: [String] = []
        segments.append(prefix(for: event))
        segments.append(describe(event))

        if let detail = detailDescription(for: event) {
            segments.append(detail)
        }

        if let metadata = event.metadata {
            segments.append("— \(metadata.summary)")
        }

        if !event.validationIssues.isEmpty {
            let issues = event.validationIssues.map(issueDescription).joined(separator: "; ")
            segments.append("[\(issues)]")
        }

        return segments.joined(separator: " ")
    }

    private func prefix(for event: ParseEvent) -> String {
        switch event.kind {
        case let .willStartBox(header, depth):
            return "[offset \(event.offset)] ▶︎ depth \(depth) \(header.identifierString)"
        case let .didFinishBox(header, depth):
            return "[offset \(event.offset)] ◀︎ depth \(depth) \(header.identifierString)"
        }
    }

    private func describe(_ event: ParseEvent) -> String {
        if let metadata = event.metadata {
            return "\(metadata.name)"
        }
        switch event.kind {
        case let .willStartBox(header, _), let .didFinishBox(header, _):
            return "Box \(header.identifierString)"
        }
    }

    private func detailDescription(for event: ParseEvent) -> String? {
        if let fragment = event.payload?.trackFragment {
            var parts: [String] = []
            if let trackID = fragment.trackID {
                parts.append("track=\(trackID)")
            }
            parts.append("samples=\(fragment.totalSampleCount)")
            if let baseDecode = fragment.baseDecodeTime {
                parts.append("base_decode_time=\(baseDecode)")
            }
            return parts.joined(separator: " ")
        }
        if let run = event.payload?.trackRun {
            var parts: [String] = []
            if let trackID = run.trackID {
                parts.append("track=\(trackID)")
            }
            parts.append("samples=\(run.sampleCount)")
            if let dataOffset = run.dataOffset {
                parts.append("data_offset=\(dataOffset)")
            }
            if let start = run.startDecodeTime {
                parts.append("start_decode=\(start)")
            }
            return parts.joined(separator: " ")
        }
        if let decodeTime = event.payload?.trackFragmentDecodeTime {
            var parts = ["base_decode_time=\(decodeTime.baseMediaDecodeTime)"]
            if decodeTime.baseMediaDecodeTimeIs64Bit {
                parts.append("(64-bit)")
            }
            return parts.joined(separator: " ")
        }
        if let fragmentHeader = event.payload?.trackFragmentHeader {
            return "track=\(fragmentHeader.trackID)"
        }
        if let fragment = event.payload?.movieFragmentHeader {
            return "sequence=\(fragment.sequenceNumber)"
        }
        if let sequenceField = event.payload?.fields.first(where: { $0.name == "sequence_number" })?.value {
            return "sequence=\(sequenceField)"
        }
        return nil
    }

    private func issueDescription(_ issue: ValidationIssue) -> String {
        "\(issue.ruleID) \(issue.severity.rawValue): \(issue.message)"
    }
}
