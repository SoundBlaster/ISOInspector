import Foundation

extension BoxParserRegistry.DefaultParsers {
    static let visualSampleEntryTypes: Set<FourCharCode> = {
        let rawValues = [
            "avc1", "avc2", "avc3", "avc4",
            "hvc1", "hev1", "dvh1", "dvhe",
            "dvav", "dvvc",
            "av01", "vp08", "vp09",
            "encv"
        ]
        let codes = rawValues.compactMap { try? FourCharCode($0) }
        return Set(codes)
    }()

    static let audioSampleEntryTypes: Set<FourCharCode> = {
        let rawValues = ["mp4a", "enca", "ac-4", "mha1", "mhm1"]
        let codes = rawValues.compactMap { try? FourCharCode($0) }
        return Set(codes)
    }()

    static let avcSampleEntryTypes: Set<FourCharCode> = {
        let rawValues = ["avc1", "avc2", "avc3", "avc4"]
        let codes = rawValues.compactMap { try? FourCharCode($0) }
        return Set(codes)
    }()

    static let hevcSampleEntryTypes: Set<FourCharCode> = {
        let rawValues = ["hvc1", "hev1", "dvh1", "dvhe"]
        let codes = rawValues.compactMap { try? FourCharCode($0) }
        return Set(codes)
    }()

    private static let protectedSampleEntryTypes: Set<FourCharCode> = {
        let rawValues = ["encv", "enca"]
        let codes = rawValues.compactMap { try? FourCharCode($0) }
        return Set(codes)
    }()

    private struct SampleEntryParseResult {
        let fields: [ParsedBoxPayload.Field]
        let nextOffset: Int64
        let startOffset: Int64
    }

    @Sendable static func sampleDescription(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else { return nil }

        var fields: [ParsedBoxPayload.Field] = []
        let start = header.payloadRange.lowerBound
        let end = header.payloadRange.upperBound

        fields.append(ParsedBoxPayload.Field(
            name: "version",
            value: String(fullHeader.version),
            description: "Structure version",
            byteRange: start..<(start + 1)
        ))

        fields.append(ParsedBoxPayload.Field(
            name: "flags",
            value: String(format: "0x%06X", fullHeader.flags),
            description: "Bit flags",
            byteRange: (start + 1)..<(start + 4)
        ))

        var cursor = fullHeader.contentStart
        guard let entryCount = try readUInt32(reader, at: cursor, end: end) else { return nil }
        fields.append(ParsedBoxPayload.Field(
            name: "entry_count",
            value: String(entryCount),
            description: "Number of sample entries",
            byteRange: cursor..<(cursor + 4)
        ))
        cursor += 4

        var index: UInt32 = 0
        while index < entryCount, cursor < end {
            guard let result = try parseSampleEntry(
                reader: reader,
                startOffset: cursor,
                end: end,
                index: Int(index)
            ) else {
                break
            }
            fields.append(contentsOf: result.fields)
            cursor = result.nextOffset
            if cursor <= result.startOffset {
                break
            }
            index += 1
        }

        return ParsedBoxPayload(fields: fields)
    }

    private static func parseSampleEntry(
        reader: RandomAccessReader,
        startOffset: Int64,
        end: Int64,
        index: Int
    ) throws -> SampleEntryParseResult? {
        guard startOffset + 8 <= end else { return nil }
        guard let declaredSize = try readUInt32(reader, at: startOffset, end: end) else { return nil }
        guard let format = try readFourCC(reader, at: startOffset + 4, end: end) else { return nil }

        let resolvedLength: Int64
        if declaredSize == 0 {
            resolvedLength = end - startOffset
        } else {
            resolvedLength = Int64(declaredSize)
        }
        guard resolvedLength > 0 else { return nil }
        let endOffsetResult = startOffset.addingReportingOverflow(resolvedLength)
        guard endOffsetResult.overflow == false else { return nil }
        let entryEnd = endOffsetResult.partialValue
        guard entryEnd <= end else { return nil }
        guard resolvedLength >= 16 else { return nil }

        var fields: [ParsedBoxPayload.Field] = []
        let recordedLength = declaredSize == 0 ? resolvedLength : Int64(declaredSize)
        fields.append(ParsedBoxPayload.Field(
            name: "entries[\(index)].byte_length",
            value: String(recordedLength),
            description: "Sample entry byte length",
            byteRange: startOffset..<(startOffset + 4)
        ))

        fields.append(ParsedBoxPayload.Field(
            name: "entries[\(index)].format",
            value: format.rawValue,
            description: "Sample entry format",
            byteRange: (startOffset + 4)..<(startOffset + 8)
        ))

        let baseStart = startOffset + 8
        let dataReferenceOffset = baseStart + 6
        guard dataReferenceOffset + 2 <= entryEnd else { return nil }
        guard let dataReferenceIndex = try readUInt16(reader, at: dataReferenceOffset, end: entryEnd) else {
            return nil
        }
        fields.append(ParsedBoxPayload.Field(
            name: "entries[\(index)].data_reference_index",
            value: String(dataReferenceIndex),
            description: "Data reference index",
            byteRange: dataReferenceOffset..<(dataReferenceOffset + 2)
        ))

        let contentStart = dataReferenceOffset + 2

        let baseHeaderLength = sampleEntryHeaderLength(for: format)

        if visualSampleEntryTypes.contains(format) {
            fields.append(contentsOf: parseVisualSampleEntry(
                reader: reader,
                contentStart: contentStart,
                entryEnd: entryEnd,
                index: index
            ))
        } else if audioSampleEntryTypes.contains(format) {
            fields.append(contentsOf: parseAudioSampleEntry(
                reader: reader,
                contentStart: contentStart,
                entryEnd: entryEnd,
                index: index
            ))
        }

        guard let headerLength = baseHeaderLength else {
            return SampleEntryParseResult(fields: fields, nextOffset: entryEnd, startOffset: startOffset)
        }

        let childBoxes = parseChildBoxes(
            reader: reader,
            contentStart: contentStart,
            entryEnd: entryEnd,
            baseHeaderLength: headerLength
        )

        var effectiveFormat = format
        if protectedSampleEntryTypes.contains(format) {
            let protection = parseProtectedSampleEntry(
                reader: reader,
                boxes: childBoxes,
                entryIndex: index
            )
            effectiveFormat = protection.originalFormat ?? format
            fields.append(contentsOf: protection.fields)
        }

        fields.append(contentsOf: parseCodecSpecificFields(
            format: effectiveFormat,
            boxes: childBoxes,
            reader: reader,
            entryIndex: index
        ))

        return SampleEntryParseResult(fields: fields, nextOffset: entryEnd, startOffset: startOffset)
    }
}
