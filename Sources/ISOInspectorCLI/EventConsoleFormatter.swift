// swiftlint:disable type_body_length
// @todo #a7 Refactor EventConsoleFormatter: Break down 195-line struct into smaller formatting components

import Foundation
import ISOInspectorKit

public struct EventConsoleFormatter: Sendable {
    public init() {}

    public func format(_ event: ParseEvent) -> String {
        var segments: [String] = []
        segments.append(prefix(for: event))
        segments.append(describe(event))

        if let detail = detailDescription(for: event) { segments.append(detail) }

        if let metadata = event.metadata { segments.append("— \(metadata.summary)") }

        if !event.validationIssues.isEmpty {
            let issues = event.validationIssues.map(issueDescription).joined(separator: "; ")
            segments.append("[\(issues)]")
        }

        return segments.joined(separator: " ")
    }

    private func prefix(for event: ParseEvent) -> String {
        switch event.kind {
        case .willStartBox(let header, let depth):
            return "[offset \(event.offset)] ▶︎ depth \(depth) \(header.identifierString)"
        case .didFinishBox(let header, let depth):
            return "[offset \(event.offset)] ◀︎ depth \(depth) \(header.identifierString)"
        }
    }

    private func describe(_ event: ParseEvent) -> String {
        if let metadata = event.metadata { return "\(metadata.name)" }
        switch event.kind {
        case .willStartBox(let header, _), .didFinishBox(let header, _):
            return "Box \(header.identifierString)"
        }
    }

    // Rationale: Central formatting dispatcher for all ISO box types. Refactoring to multiple formatters would reduce clarity.
    // @todo #A7 Consider extracting box-type-specific formatters if complexity grows beyond current threshold.
    // swiftlint:disable:next cyclomatic_complexity
    private func detailDescription(for event: ParseEvent) -> String? {
        if let encryption = event.payload?.sampleEncryption {
            var parts: [String] = ["encryption", "samples=\(encryption.sampleCount)"]
            parts.append(
                "override_defaults=\(encryption.overrideTrackEncryptionDefaults ? "true" : "false")"
            )
            parts.append("subsample=\(encryption.usesSubsampleEncryption ? "true" : "false")")
            if let ivSize = encryption.perSampleIVSize { parts.append("iv_size=\(ivSize)") }
            if let algorithm = encryption.algorithmIdentifier {
                parts.append(String(format: "algorithm=0x%06X", algorithm))
            }
            if let sampleBytes = encryption.sampleInfoByteLength {
                parts.append("sample_bytes=\(sampleBytes)")
            }
            if let sampleRange = encryption.sampleInfoRange {
                parts.append("sample_range=\(sampleRange.lowerBound)-\(sampleRange.upperBound)")
            }
            if let keyRange = encryption.keyIdentifierRange {
                parts.append("key_range=\(keyRange.lowerBound)-\(keyRange.upperBound)")
            }
            if let constantBytes = encryption.constantIVByteLength {
                parts.append("constant_iv=\(constantBytes)")
            }
            if let constantRange = encryption.constantIVRange {
                parts.append(
                    "constant_range=\(constantRange.lowerBound)-\(constantRange.upperBound)")
            }
            return parts.joined(separator: " ")
        }
        if let offsets = event.payload?.sampleAuxInfoOffsets {
            var parts: [String] = ["aux_offsets", "entries=\(offsets.entryCount)"]
            parts.append("bytes_per_entry=\(offsets.entrySizeBytes)")
            if let type = offsets.auxInfoType { parts.append("type=\(type.rawValue)") }
            if let parameter = offsets.auxInfoTypeParameter {
                parts.append("parameter=\(parameter)")
            }
            if let entriesLength = offsets.entriesByteLength {
                parts.append("bytes=\(entriesLength)")
            }
            if let range = offsets.entriesRange {
                parts.append("range=\(range.lowerBound)-\(range.upperBound)")
            }
            return parts.joined(separator: " ")
        }
        if let sizes = event.payload?.sampleAuxInfoSizes {
            var parts: [String] = ["aux_sizes", "entry_count=\(sizes.entryCount)"]
            parts.append("default=\(sizes.defaultSampleInfoSize)")
            if let type = sizes.auxInfoType { parts.append("type=\(type.rawValue)") }
            if let parameter = sizes.auxInfoTypeParameter { parts.append("parameter=\(parameter)") }
            if let variableBytes = sizes.variableEntriesByteLength {
                parts.append("variable_bytes=\(variableBytes)")
            }
            if let range = sizes.variableEntriesRange {
                parts.append("range=\(range.lowerBound)-\(range.upperBound)")
            }
            return parts.joined(separator: " ")
        }
        if let table = event.payload?.trackFragmentRandomAccess {
            var parts: [String] = []
            parts.append("track=\(table.trackID)")
            parts.append("entries=\(table.entries.count)")
            if let fragment = table.entries.compactMap({ $0.fragmentSequenceNumber }).sorted().first
            {
                parts.append("fragment=\(fragment)")
            }
            if let firstEntry = table.entries.first {
                parts.append(
                    "sample=traf\(firstEntry.trafNumber):trun\(firstEntry.trunNumber):\(firstEntry.sampleNumber)"
                )
                if let decode = firstEntry.resolvedDecodeTime { parts.append("decode=\(decode)") }
                if let offset = firstEntry.resolvedDataOffset { parts.append("offset=\(offset)") }
            }
            return parts.joined(separator: " ")
        }
        if let summary = event.payload?.movieFragmentRandomAccess {
            var parts: [String] = []
            parts.append("tracks=\(summary.tracks.count)")
            parts.append("total_entries=\(summary.totalEntryCount)")
            let fragments = summary.tracks.flatMap { $0.referencedFragmentSequenceNumbers }.sorted()
            if !fragments.isEmpty {
                let joined = fragments.map(String.init).joined(separator: ",")
                parts.append("fragments=[\(joined)]")
            }
            if let size = summary.offset?.mfraSize { parts.append("mfra_size=\(size)") }
            return parts.joined(separator: " ")
        }
        if let fragment = event.payload?.trackFragment {
            var parts: [String] = []
            if let trackID = fragment.trackID { parts.append("track=\(trackID)") }
            parts.append("runs=\(fragment.runs.count)")
            parts.append("samples=\(fragment.totalSampleCount)")
            if let totalDuration = fragment.totalSampleDuration {
                parts.append("duration=\(totalDuration)")
            }
            if let totalSize = fragment.totalSampleSize { parts.append("size=\(totalSize)") }
            if let baseData = fragment.baseDataOffset {
                parts.append("base_data_offset=\(baseData)")
            }
            if let baseDecode = fragment.baseDecodeTime {
                parts.append("base_decode=\(baseDecode)")
            }
            if let firstDecode = fragment.firstDecodeTime, let lastDecode = fragment.lastDecodeTime
            {
                parts.append("decode=\(firstDecode)-\(lastDecode)")
            } else if let first = fragment.firstDecodeTime ?? fragment.baseDecodeTime {
                parts.append("decode_start=\(first)")
            }
            if let earliest = fragment.earliestPresentationTime,
                let latest = fragment.latestPresentationTime
            {
                parts.append("presentation=\(earliest)-\(latest)")
            }
            return parts.joined(separator: " ")
        }
        if let run = event.payload?.trackRun {
            var parts: [String] = []
            if let trackID = run.trackID { parts.append("track=\(trackID)") }
            if let runIndex = run.runIndex { parts.append("run=\(runIndex)") }
            parts.append("samples=\(run.sampleCount)")
            if let firstSample = run.firstSampleGlobalIndex {
                parts.append("first_sample=\(firstSample)")
            }
            if let totalDuration = run.totalSampleDuration {
                parts.append("duration=\(totalDuration)")
            }
            if let totalSize = run.totalSampleSize { parts.append("size=\(totalSize)") }
            if let dataOffset = run.dataOffset { parts.append("data_offset=\(dataOffset)") }
            if let start = run.startDataOffset, let end = run.endDataOffset {
                parts.append("data_range=\(start)-\(end)")
            } else if run.dataOffset != nil {
                parts.append("data_range=unresolved")
            }
            if let startDecode = run.startDecodeTime, let endDecode = run.endDecodeTime {
                parts.append("decode=\(startDecode)-\(endDecode)")
            } else if let singleDecode = run.startDecodeTime ?? run.endDecodeTime {
                parts.append("decode=\(singleDecode)")
            } else if run.sampleCount > 0 {
                parts.append("decode=unresolved")
            }
            if let startPresentation = run.startPresentationTime,
                let endPresentation = run.endPresentationTime
            {
                parts.append("presentation=\(startPresentation)-\(endPresentation)")
            }
            return parts.joined(separator: " ")
        }
        if let decodeTime = event.payload?.trackFragmentDecodeTime {
            var parts = ["base_decode_time=\(decodeTime.baseMediaDecodeTime)"]
            if decodeTime.baseMediaDecodeTimeIs64Bit { parts.append("(64-bit)") }
            return parts.joined(separator: " ")
        }
        if let fragmentHeader = event.payload?.trackFragmentHeader {
            return "track=\(fragmentHeader.trackID)"
        }
        if let fragment = event.payload?.movieFragmentHeader {
            return "sequence=\(fragment.sequenceNumber)"
        }
        if let sequenceField = event.payload?.fields.first(where: { $0.name == "sequence_number" })?
            .value
        {
            return "sequence=\(sequenceField)"
        }
        return nil
    }

    private func issueDescription(_ issue: ValidationIssue) -> String {
        "\(issue.ruleID) \(issue.severity.rawValue): \(issue.message)"
    }
}
