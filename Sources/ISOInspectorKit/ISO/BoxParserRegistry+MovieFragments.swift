import Foundation

extension BoxParserRegistry.DefaultParsers {
    static func movieFragment(header: BoxHeader, reader _: RandomAccessReader) throws -> ParsedBoxPayload? {
        guard header.payloadRange.lowerBound <= header.payloadRange.upperBound else { return nil }
        return ParsedBoxPayload()
    }

    static func movieFragmentHeader(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else { return nil }

        let payloadStart = header.payloadRange.lowerBound
        let payloadEnd = fullHeader.contentRange.upperBound

        var fields: [ParsedBoxPayload.Field] = []
        fields.append(ParsedBoxPayload.Field(
            name: "version",
            value: String(fullHeader.version),
            description: "Structure version",
            byteRange: payloadStart..<(payloadStart + 1)
        ))

        fields.append(ParsedBoxPayload.Field(
            name: "flags",
            value: String(format: "0x%06X", fullHeader.flags),
            description: "Bit flags",
            byteRange: (payloadStart + 1)..<(payloadStart + 4)
        ))

        let cursor = fullHeader.contentStart
        guard let sequenceNumber = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
        let sequenceRange = cursor..<(cursor + 4)
        fields.append(ParsedBoxPayload.Field(
            name: "sequence_number",
            value: String(sequenceNumber),
            description: "Fragment sequence number",
            byteRange: sequenceRange
        ))

        let detail = ParsedBoxPayload.Detail.movieFragmentHeader(
            ParsedBoxPayload.MovieFragmentHeaderBox(
                version: fullHeader.version,
                flags: fullHeader.flags,
                sequenceNumber: sequenceNumber
            )
        )

        return ParsedBoxPayload(fields: fields, detail: detail)
    }

    static func trackFragmentHeader(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else { return nil }

        let payloadStart = header.payloadRange.lowerBound
        let payloadEnd = fullHeader.contentRange.upperBound

        var fields: [ParsedBoxPayload.Field] = []
        fields.append(ParsedBoxPayload.Field(
            name: "version",
            value: String(fullHeader.version),
            description: "Structure version",
            byteRange: payloadStart..<(payloadStart + 1)
        ))

        fields.append(ParsedBoxPayload.Field(
            name: "flags",
            value: String(format: "0x%06X", fullHeader.flags),
            description: "Bit flags",
            byteRange: (payloadStart + 1)..<(payloadStart + 4)
        ))

        var cursor = fullHeader.contentStart
        guard let trackID = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
        let trackRange = cursor..<(cursor + 4)
        fields.append(ParsedBoxPayload.Field(
            name: "track_id",
            value: String(trackID),
            description: "Track identifier",
            byteRange: trackRange
        ))

        cursor += 4

        var baseDataOffset: UInt64?
        if fullHeader.flags & 0x000001 != 0 {
            guard let value = try readUInt64(reader, at: cursor, end: payloadEnd) else { return nil }
            baseDataOffset = value
            let range = cursor..<(cursor + 8)
            fields.append(ParsedBoxPayload.Field(
                name: "base_data_offset",
                value: String(value),
                description: "Absolute data offset",
                byteRange: range
            ))
            cursor += 8
        }

        var sampleDescriptionIndex: UInt32?
        if fullHeader.flags & 0x000002 != 0 {
            guard let value = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
            sampleDescriptionIndex = value
            let range = cursor..<(cursor + 4)
            fields.append(ParsedBoxPayload.Field(
                name: "sample_description_index",
                value: String(value),
                description: "Sample description index override",
                byteRange: range
            ))
            cursor += 4
        }

        var defaultSampleDuration: UInt32?
        if fullHeader.flags & 0x000008 != 0 {
            guard let value = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
            defaultSampleDuration = value
            let range = cursor..<(cursor + 4)
            fields.append(ParsedBoxPayload.Field(
                name: "default_sample_duration",
                value: String(value),
                description: "Default sample duration override",
                byteRange: range
            ))
            cursor += 4
        }

        var defaultSampleSize: UInt32?
        if fullHeader.flags & 0x000010 != 0 {
            guard let value = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
            defaultSampleSize = value
            let range = cursor..<(cursor + 4)
            fields.append(ParsedBoxPayload.Field(
                name: "default_sample_size",
                value: String(value),
                description: "Default sample size override",
                byteRange: range
            ))
            cursor += 4
        }

        var defaultSampleFlags: UInt32?
        if fullHeader.flags & 0x000020 != 0 {
            guard let value = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
            defaultSampleFlags = value
            let range = cursor..<(cursor + 4)
            fields.append(ParsedBoxPayload.Field(
                name: "default_sample_flags",
                value: String(format: "0x%08X", value),
                description: "Default sample flags override",
                byteRange: range
            ))
            cursor += 4
        }

        let durationIsEmpty = (fullHeader.flags & 0x000100) != 0
        let defaultBaseIsMoof = (fullHeader.flags & 0x000200) != 0

        fields.append(ParsedBoxPayload.Field(
            name: "duration_is_empty",
            value: boolString(durationIsEmpty),
            description: "Indicates empty duration",
            byteRange: nil
        ))

        fields.append(ParsedBoxPayload.Field(
            name: "default_base_is_moof",
            value: boolString(defaultBaseIsMoof),
            description: "Use moof offset as base",
            byteRange: nil
        ))

        let detail = ParsedBoxPayload.Detail.trackFragmentHeader(
            ParsedBoxPayload.TrackFragmentHeaderBox(
                version: fullHeader.version,
                flags: fullHeader.flags,
                trackID: trackID,
                baseDataOffset: baseDataOffset,
                sampleDescriptionIndex: sampleDescriptionIndex,
                defaultSampleDuration: defaultSampleDuration,
                defaultSampleSize: defaultSampleSize,
                defaultSampleFlags: defaultSampleFlags,
                durationIsEmpty: durationIsEmpty,
                defaultBaseIsMoof: defaultBaseIsMoof
            )
        )

        return ParsedBoxPayload(fields: fields, detail: detail)
    }

    // @todo PDD:45min #D3 Parse `tfdt` and `trun` boxes plus aggregate `traf` container metadata to surface sample timing and offsets.
    // The D3 micro-PRD in DOCS/TASK_ARCHIVE/136_Summary_of_Work_2025-10-21_tfhd_Track_Fragment_Header/D3_traf_tfhd_tfdt_trun_Parsing.md outlines the remaining fragment run parsing work.
}
