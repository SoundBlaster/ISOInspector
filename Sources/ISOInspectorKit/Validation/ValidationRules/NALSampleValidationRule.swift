import Foundation

/// Validates NAL framing in unencrypted, self-contained, non-fragmented video samples.
final class NALSampleValidationRule: BoxValidationRule, @unchecked Sendable {
    private enum Table<Value> {
        case missing
        case available(Value)
    }

    private enum TrackIdentity {
        case unspecified
        case numbered(UInt32)
    }

    private struct Context {
        var identity: TrackIdentity = .unspecified
        var descriptions: [UInt32: Description] = [:]
        var dataReferences: [ParsedBoxPayload.DataReferenceBox.Entry] = []
        var sampleToChunk: Table<ParsedBoxPayload.SampleToChunkBox> = .missing
        var sizes: Table<Sizes> = .missing
        var chunks: Table<ParsedBoxPayload.ChunkOffsetBox> = .missing
    }

    private struct Description {
        let lengthBytes: Int
        let dataReference: UInt32
    }

    private struct Sizes {
        let count: UInt32
        let defaultSize: UInt32
        let entries: [UInt32]
    }

    private var tracks: [Context] = []

    func issues(for event: ParseEvent, reader: any RandomAccessReader) throws -> [ValidationIssue] {
        switch event.kind {
        case .willStartBox(let header, _):
            if header.type.rawValue == "trak" { tracks.append(Context()); return [] }
            guard let index = tracks.indices.last else { return [] }
            switch header.type.rawValue {
            case "tkhd":
                if let track = event.payload?.trackHeader { tracks[index].identity = .numbered(track.trackID) }
            case "dref": tracks[index].dataReferences = event.payload?.dataReference?.entries ?? []
            case "stsd": tracks[index].descriptions = descriptions(from: event.payload?.fields ?? [])
            case "stsc":
                if let box = event.payload?.sampleToChunk { tracks[index].sampleToChunk = .available(box) }
            case "stco", "co64":
                if let box = event.payload?.chunkOffset { tracks[index].chunks = .available(box) }
            case "stsz":
                if let box = event.payload?.sampleSize {
                    tracks[index].sizes = .available(Sizes(count: box.sampleCount, defaultSize: box.defaultSampleSize, entries: box.entries.map(\.size)))
                }
            case "stz2":
                if let box = event.payload?.compactSampleSize {
                    tracks[index].sizes = .available(Sizes(count: box.sampleCount, defaultSize: 0, entries: box.entries.map(\.size)))
                }
            default: break
            }
            return []
        case .didFinishBox(let header, _):
            guard header.type.rawValue == "trak", let context = tracks.popLast() else { return [] }
            return try validate(context, reader: reader)
        }
    }

    private func descriptions(from fields: [ParsedBoxPayload.Field]) -> [UInt32: Description] {
        guard let countField = fields.first(where: { $0.name == "entry_count" }),
            let count = UInt32(countField.value), Int(count) <= fields.count else { return [:] }
        var result: [UInt32: Description] = [:]
        for index in 0..<count {
            let prefix = "entries[\(index)]"
            func value(_ suffix: String) -> String? { fields.first { $0.name == "\(prefix).\(suffix)" }?.value }
            guard let format = value("format"), let referenceText = value("data_reference_index"),
                let reference = UInt32(referenceText), reference > 0 else { continue }
            let codec: String
            switch format {
            case "avc1", "avc2", "avc3", "avc4": codec = "avc"
            case "hvc1", "hev1": codec = "hevc"
            default: continue
            }
            guard let widthText = value("codec.\(codec).nal_unit_length_bytes"),
                let width = Int(widthText), [1, 2, 4].contains(width) else { continue }
            result[index + 1] = Description(lengthBytes: width, dataReference: reference)
        }
        return result
    }

    private func validate(_ context: Context, reader: any RandomAccessReader) throws -> [ValidationIssue] {
        guard !context.descriptions.isEmpty,
            case .available(let sampleToChunk) = context.sampleToChunk,
            case .available(let sizes) = context.sizes,
            case .available(let chunkOffsets) = context.chunks else { return [] }
        let mapping = sampleToChunk.entries
        let chunks = chunkOffsets.entries
        guard !mapping.isEmpty, mapping[0].firstChunk == 1 else { return [] }
        guard sizes.defaultSize != 0 || sizes.entries.count == Int(sizes.count) else { return [] }
        for index in mapping.indices {
            guard mapping[index].samplesPerChunk > 0, mapping[index].sampleDescriptionIndex > 0 else { return [] }
            if index > 0, mapping[index - 1].firstChunk >= mapping[index].firstChunk { return [] }
        }
        var issues: [ValidationIssue] = []
        var sampleIndex = 0
        var mappingIndex = 0
        for (chunkIndex, chunk) in chunks.enumerated() {
            try Task.checkCancellation()
            let chunkNumber = UInt64(chunkIndex) + 1
            while mappingIndex + 1 < mapping.count && UInt64(mapping[mappingIndex + 1].firstChunk) <= chunkNumber {
                mappingIndex += 1
            }
            let entry = mapping[mappingIndex]
            guard let start = Int64(exactly: chunk.offset) else { return issues }
            var offset = start
            for _ in 0..<entry.samplesPerChunk {
                try Task.checkCancellation()
                guard sampleIndex < Int(sizes.count) else { return issues }
                if sampleIndex >= 1_000_000 {
                    issues.append(ValidationIssue(ruleID: "VR-019", message: "NAL framing validation stopped after 1000000 samples.", severity: .warning))
                    return issues
                }
                let size = sizes.defaultSize == 0 ? sizes.entries[sampleIndex] : sizes.defaultSize
                let end = offset.addingReportingOverflow(Int64(size))
                guard !end.overflow, offset >= 0, end.partialValue <= reader.length else { return issues }
                if let description = context.descriptions[entry.sampleDescriptionIndex],
                    context.dataReferences.contains(where: { $0.index == description.dataReference - 1 && $0.location == .selfContained }) {
                    do {
                        try NALUnitFraming.validate(reader: reader, range: offset..<end.partialValue, lengthBytes: description.lengthBytes)
                    } catch let failure as NALUnitFraming.Failure {
                        let track: String
                        switch context.identity {
                        case .unspecified: track = "Track"
                        case .numbered(let id): track = "Track \(id)"
                        }
                        let message = describe(failure, sampleOffset: offset, lengthBytes: description.lengthBytes)
                        issues.append(ValidationIssue(ruleID: "VR-019", message: "\(track) sample \(sampleIndex + 1): \(message)", severity: .error))
                        if issues.count == 100 {
                            issues.append(ValidationIssue(ruleID: "VR-019", message: "NAL framing validation stopped after 100 errors.", severity: .warning))
                            return issues
                        }
                    }
                }
                sampleIndex += 1
                offset = end.partialValue
            }
        }
        return issues
    }

    private func describe(_ failure: NALUnitFraming.Failure, sampleOffset: Int64, lengthBytes: Int) -> String {
        switch failure {
        case .invalidLengthWidth(let width):
            return "Invalid NAL length field width \(width)."
        case .truncatedLength(let offset, let expected, let available):
            return "Truncated NAL length at file offset \(sampleOffset + Int64(offset)): expected \(expected) bytes, found \(available)."
        case .emptyUnit(let offset):
            return "Zero-length NAL unit at file offset \(sampleOffset + Int64(offset))."
        case .truncatedUnit(let offset, let declared, let available):
            let prefixOffset = sampleOffset + Int64(offset - lengthBytes)
            return "NAL length \(declared) at file offset \(prefixOffset) exceeds \(available) bytes remaining in sample."
        }
    }
}
