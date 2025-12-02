import Foundation

/// Validates codec configuration boxes for AVC (H.264) and HEVC (H.265) streams.
///
/// Video codec configuration boxes (avcC, hvcC) contain critical decoder initialization
/// data including parameter sets (SPS, PPS, VPS). This rule validates:
///
/// ## AVC (H.264) Configuration (avcC)
/// - NAL unit length field is 1-4 bytes
/// - Declared SPS count matches available payload
/// - Declared PPS count matches available payload
/// - No zero-length parameter sets
///
/// ## HEVC (H.265) Configuration (hvcC)
/// - NAL unit length field is 1-4 bytes
/// - Declared NAL array count matches payload
/// - Each array's NAL unit count is consistent
/// - No zero-length NAL units
///
/// ## Rule ID
/// - **VR-018**: Codec configuration validation
///
/// ## Severity
/// - **Error**: Invalid configuration, truncated payload, or inconsistent counts
///
/// ## Example Violations
/// - avcC declares 2 SPS but payload only contains 1
/// - hvcC declares 5-byte NAL lengths (invalid, must be 1-4)
/// - avcC SPS #0 has zero length
final class CodecConfigurationValidationRule: BoxValidationRule, @unchecked Sendable {  // swiftlint:disable:this type_body_length
    private struct TrackContext { var trackHeader: ParsedBoxPayload.TrackHeaderBox? }

    private struct SampleEntry {
        let index: Int
        let format: FourCharCode
        let effectiveFormat: FourCharCode
        let nestedBoxes: [BoxParserRegistry.DefaultParsers.NestedBox]
    }

    private var trackStack: [TrackContext] = []

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        switch event.kind {
        case .willStartBox(let header, let depth):
            trimStack(to: depth)

            if header.type == BoxType.track {
                trackStack.append(TrackContext())
                return []
            }

            if let trackIndex = trackStack.indices.last, header.type == BoxType.trackHeader {
                if let detail = event.payload?.trackHeader {
                    trackStack[trackIndex].trackHeader = detail
                }
                return []
            }

            if header.type == BoxType.sampleDescription {
                return sampleDescriptionIssues(
                    header: header, reader: reader, trackContext: trackStack.last)
            }

            return []

        case .didFinishBox(let header, let depth):
            trimStack(to: depth)
            if header.type == BoxType.track, !trackStack.isEmpty { trackStack.removeLast() }
            return []
        }
    }

    private func trimStack(to depth: Int) {
        if trackStack.count > depth { trackStack.removeLast(trackStack.count - depth) }
    }

    private func sampleDescriptionIssues(
        header: BoxHeader, reader: RandomAccessReader, trackContext: TrackContext?
    ) -> [ValidationIssue] {
        let entries = sampleEntries(for: header, reader: reader)
        guard !entries.isEmpty else { return [] }

        var issues: [ValidationIssue] = []
        let trackLabel = trackDescription(for: trackContext)

        for entry in entries {
            let prefix = entryPrefix(
                trackLabel: trackLabel, entryIndex: entry.index, format: entry.effectiveFormat)

            if BoxParserRegistry.DefaultParsers.avcSampleEntryTypes.contains(entry.effectiveFormat)
            {
                for box in entry.nestedBoxes where box.type.rawValue == "avcC" {
                    issues.append(contentsOf: avcIssues(prefix: prefix, box: box, reader: reader))
                }
            }

            if BoxParserRegistry.DefaultParsers.hevcSampleEntryTypes.contains(entry.effectiveFormat)
            {
                for box in entry.nestedBoxes where box.type.rawValue == "hvcC" {
                    issues.append(contentsOf: hevcIssues(prefix: prefix, box: box, reader: reader))
                }
            }
        }

        return issues
    }

    private func trackDescription(for context: TrackContext?) -> String {
        if let trackID = context?.trackHeader?.trackID { return "Track \(trackID)" }
        return "Track"
    }

    private func entryPrefix(trackLabel: String, entryIndex: Int, format: FourCharCode) -> String {
        "\(trackLabel) sample description entry \(entryIndex) (format \(format.rawValue))"
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func sampleEntries(for header: BoxHeader, reader: RandomAccessReader) -> [SampleEntry] {
        let payloadStart = header.payloadRange.lowerBound
        let payloadEnd = header.payloadRange.upperBound
        guard payloadEnd > payloadStart else { return [] }

        var cursor = payloadStart
        guard cursor + 8 <= payloadEnd else { return [] }
        cursor += 4

        guard
            let entryCountValue = try? BoxParserRegistry.DefaultParsers.readUInt32(
                reader, at: cursor, end: payloadEnd)
        else { return [] }
        let entryCount = Int(entryCountValue)
        cursor += 4

        var entries: [SampleEntry] = []
        var index = 0

        while index < entryCount, cursor + 8 <= payloadEnd {
            guard
                let declaredSizeValue = try? BoxParserRegistry.DefaultParsers.readUInt32(
                    reader, at: cursor, end: payloadEnd),
                let format = try? BoxParserRegistry.DefaultParsers.readFourCC(
                    reader, at: cursor + 4, end: payloadEnd)
            else { break }

            var headerLength: Int64 = 8
            var entryLength: Int64?
            switch declaredSizeValue {
            case 0: entryLength = payloadEnd - cursor
            case 1:
                guard
                    let largeSize = try? BoxParserRegistry.DefaultParsers.readUInt64(
                        reader, at: cursor + 8, end: payloadEnd),
                    let converted = Int64(exactly: largeSize)
                else { break }
                headerLength = 16
                entryLength = converted
            default: entryLength = Int64(declaredSizeValue)
            }

            guard let resolvedLength = entryLength, resolvedLength >= headerLength else { break }
            let entryEnd = cursor + resolvedLength
            guard entryEnd <= payloadEnd, entryEnd > cursor else { break }

            let contentStart = cursor + headerLength

            var nestedBoxes: [BoxParserRegistry.DefaultParsers.NestedBox] = []
            if let baseHeaderLength = BoxParserRegistry.DefaultParsers.sampleEntryHeaderLength(
                for: format)
            {
                nestedBoxes = BoxParserRegistry.DefaultParsers.parseChildBoxes(
                    reader: reader, contentStart: contentStart, entryEnd: entryEnd,
                    baseHeaderLength: baseHeaderLength)
            }

            var effectiveFormat = format
            if format.rawValue == "encv" || format.rawValue == "enca" {
                let protection = BoxParserRegistry.DefaultParsers.parseProtectedSampleEntry(
                    reader: reader, boxes: nestedBoxes, entryIndex: index)
                if let original = protection.originalFormat { effectiveFormat = original }
            }

            entries.append(
                SampleEntry(
                    index: index, format: format, effectiveFormat: effectiveFormat,
                    nestedBoxes: nestedBoxes))

            cursor = entryEnd
            index += 1
        }

        return entries
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func avcIssues(
        prefix: String, box: BoxParserRegistry.DefaultParsers.NestedBox, reader: RandomAccessReader
    ) -> [ValidationIssue] {
        guard let data = readData(for: box, reader: reader) else {
            return [
                ValidationIssue(
                    ruleID: "VR-018",
                    message:
                        "\(prefix) avcC payload truncated; unable to read configuration bytes.",
                    severity: .error)
            ]
        }

        if data.count < 5 {
            return [
                ValidationIssue(
                    ruleID: "VR-018",
                    message:
                        "\(prefix) avcC missing length_size_minus_one field (payload \(data.count) bytes).",
                    severity: .error)
            ]
        }

        var issues: [ValidationIssue] = []

        let lengthSizeMinusOne = Int(data[4] & 0x03)
        let nalLengthBytes = lengthSizeMinusOne + 1
        if !(1...4).contains(nalLengthBytes) {
            issues.append(
                ValidationIssue(
                    ruleID: "VR-018",
                    message:
                        "\(prefix) avcC declares \(nalLengthBytes)-byte NAL unit lengths; expected 1-4 bytes.",
                    severity: .error))
        }

        guard data.count >= 6 else { return issues }
        let declaredSps = Int(data[5] & 0x1F)
        var offset = 6

        for spsIndex in 0..<declaredSps {
            guard offset + 2 <= data.count else {
                issues.append(
                    ValidationIssue(
                        ruleID: "VR-018",
                        message:
                            "\(prefix) avcC declares \(declaredSps) sequence parameter sets but payload only provides \(spsIndex) before the length field for entry #\(spsIndex).",
                        severity: .error))
                return issues
            }

            let length = Int(data[offset]) << 8 | Int(data[offset + 1])
            offset += 2

            if length == 0 {
                issues.append(
                    ValidationIssue(
                        ruleID: "VR-018",
                        message:
                            "\(prefix) avcC sequence parameter set #\(spsIndex) has zero length.",
                        severity: .error))
                continue
            }

            guard offset + length <= data.count else {
                let remaining = data.count - offset
                issues.append(
                    ValidationIssue(
                        ruleID: "VR-018",
                        message:
                            "\(prefix) avcC declares \(declaredSps) sequence parameter sets but entry #\(spsIndex) length \(length) exceeds remaining payload (\(remaining) bytes).",
                        severity: .error))
                return issues
            }

            offset += length
        }

        guard offset < data.count else {
            if declaredSps > 0 {
                issues.append(
                    ValidationIssue(
                        ruleID: "VR-018",
                        message:
                            "\(prefix) avcC declares \(declaredSps) sequence parameter sets but payload omits picture parameter set count.",
                        severity: .error))
            }
            return issues
        }

        let declaredPps = Int(data[offset])
        offset += 1

        for ppsIndex in 0..<declaredPps {
            guard offset + 2 <= data.count else {
                issues.append(
                    ValidationIssue(
                        ruleID: "VR-018",
                        message:
                            "\(prefix) avcC declares \(declaredPps) picture parameter sets but payload only provides \(ppsIndex) before the length field for entry #\(ppsIndex).",
                        severity: .error))
                return issues
            }

            let length = Int(data[offset]) << 8 | Int(data[offset + 1])
            offset += 2

            if length == 0 {
                issues.append(
                    ValidationIssue(
                        ruleID: "VR-018",
                        message:
                            "\(prefix) avcC picture parameter set #\(ppsIndex) has zero length.",
                        severity: .error))
                continue
            }

            guard offset + length <= data.count else {
                let remaining = data.count - offset
                issues.append(
                    ValidationIssue(
                        ruleID: "VR-018",
                        message:
                            "\(prefix) avcC declares \(declaredPps) picture parameter sets but entry #\(ppsIndex) length \(length) exceeds remaining payload (\(remaining) bytes).",
                        severity: .error))
                return issues
            }

            offset += length
        }

        return issues
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func hevcIssues(
        prefix: String, box: BoxParserRegistry.DefaultParsers.NestedBox, reader: RandomAccessReader
    ) -> [ValidationIssue] {
        guard let data = readData(for: box, reader: reader) else {
            return [
                ValidationIssue(
                    ruleID: "VR-018",
                    message:
                        "\(prefix) hvcC payload truncated; unable to read configuration bytes.",
                    severity: .error)
            ]
        }

        if data.count < 23 {
            return [
                ValidationIssue(
                    ruleID: "VR-018",
                    message:
                        "\(prefix) hvcC missing length_size_minus_one field (payload \(data.count) bytes).",
                    severity: .error)
            ]
        }

        var issues: [ValidationIssue] = []

        let lengthSizeMinusOne = Int(data[21] & 0x03)
        let nalLengthBytes = lengthSizeMinusOne + 1
        if !(1...4).contains(nalLengthBytes) {
            issues.append(
                ValidationIssue(
                    ruleID: "VR-018",
                    message:
                        "\(prefix) hvcC declares \(nalLengthBytes)-byte NAL unit lengths; expected 1-4 bytes.",
                    severity: .error))
        }

        let declaredArrays = Int(data[22])
        var offset = 23

        for arrayIndex in 0..<declaredArrays {
            guard offset + 3 <= data.count else {
                issues.append(
                    ValidationIssue(
                        ruleID: "VR-018",
                        message:
                            "\(prefix) hvcC declares \(declaredArrays) NAL arrays but payload only provides \(arrayIndex) before array #\(arrayIndex) header.",
                        severity: .error))
                return issues
            }

            let headerByte = data[offset]
            let nalType = headerByte & 0x3F
            let declaredNalus = Int(data[offset + 1]) << 8 | Int(data[offset + 2])
            offset += 3

            for nalIndex in 0..<declaredNalus {
                guard offset + 2 <= data.count else {
                    issues.append(
                        ValidationIssue(
                            ruleID: "VR-018",
                            message:
                                "\(prefix) hvcC NAL array (type \(nalTypeName(nalType))) declares \(declaredNalus) NAL units but payload only provides \(nalIndex) before the length field for entry #\(nalIndex).",
                            severity: .error))
                    return issues
                }

                let length = Int(data[offset]) << 8 | Int(data[offset + 1])
                offset += 2

                if length == 0 {
                    issues.append(
                        ValidationIssue(
                            ruleID: "VR-018",
                            message:
                                "\(prefix) hvcC \(nalTypeName(nalType)) NAL #\(nalIndex) has zero length.",
                            severity: .error))
                    continue
                }

                guard offset + length <= data.count else {
                    let remaining = data.count - offset
                    issues.append(
                        ValidationIssue(
                            ruleID: "VR-018",
                            message:
                                "\(prefix) hvcC NAL array (type \(nalTypeName(nalType))) declares \(declaredNalus) NAL units but entry #\(nalIndex) length \(length) exceeds remaining payload (\(remaining) bytes).",
                            severity: .error))
                    return issues
                }

                offset += length
            }
        }

        return issues
    }

    private func readData(
        for box: BoxParserRegistry.DefaultParsers.NestedBox, reader: RandomAccessReader
    ) -> Data? {
        let count64 = box.payloadRange.upperBound - box.payloadRange.lowerBound
        guard count64 > 0, count64 <= Int64(Int.max) else { return nil }
        let count = Int(count64)
        do {
            return try BoxParserRegistry.DefaultParsers.readData(
                reader, at: box.payloadRange.lowerBound, count: count,
                end: box.payloadRange.upperBound)
        } catch { return nil }
    }

    private func nalTypeName(_ type: UInt8) -> String {
        switch type {
        case 32: return "VPS"
        case 33: return "SPS"
        case 34: return "PPS"
        default: return "NAL type \(type)"
        }
    }

    private enum BoxType {
        static let track = try! FourCharCode("trak")
        static let trackHeader = try! FourCharCode("tkhd")
        static let sampleDescription = try! FourCharCode("stsd")
    }
}
