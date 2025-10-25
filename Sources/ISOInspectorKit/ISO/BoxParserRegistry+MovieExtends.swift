import Foundation

extension BoxParserRegistry.DefaultParsers {
    @Sendable static func movieExtends(header: BoxHeader, reader _: RandomAccessReader) throws -> ParsedBoxPayload? {
        guard header.payloadRange.lowerBound <= header.payloadRange.upperBound else { return nil }
        return ParsedBoxPayload()
    }

    @Sendable static func trackExtends(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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
        fields.append(ParsedBoxPayload.Field(
            name: "track_ID",
            value: String(trackID),
            description: "Track identifier",
            byteRange: cursor..<(cursor + 4)
        ))
        cursor += 4

        guard let defaultSampleDescriptionIndex = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
        fields.append(ParsedBoxPayload.Field(
            name: "default_sample_description_index",
            value: String(defaultSampleDescriptionIndex),
            description: "Default sample description table index",
            byteRange: cursor..<(cursor + 4)
        ))
        cursor += 4

        guard let defaultSampleDuration = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
        fields.append(ParsedBoxPayload.Field(
            name: "default_sample_duration",
            value: String(defaultSampleDuration),
            description: "Default sample duration in timescale units",
            byteRange: cursor..<(cursor + 4)
        ))
        cursor += 4

        guard let defaultSampleSize = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
        fields.append(ParsedBoxPayload.Field(
            name: "default_sample_size",
            value: String(defaultSampleSize),
            description: "Default sample size in bytes",
            byteRange: cursor..<(cursor + 4)
        ))
        cursor += 4

        guard let defaultSampleFlags = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
        fields.append(ParsedBoxPayload.Field(
            name: "default_sample_flags",
            value: String(format: "0x%08X", defaultSampleFlags),
            description: "Default sample flags applied to fragment samples",
            byteRange: cursor..<(cursor + 4)
        ))

        let detail = ParsedBoxPayload.Detail.trackExtends(
            ParsedBoxPayload.TrackExtendsDefaultsBox(
                version: fullHeader.version,
                flags: fullHeader.flags,
                trackID: trackID,
                defaultSampleDescriptionIndex: defaultSampleDescriptionIndex,
                defaultSampleDuration: defaultSampleDuration,
                defaultSampleSize: defaultSampleSize,
                defaultSampleFlags: defaultSampleFlags
            )
        )

        return ParsedBoxPayload(fields: fields, detail: detail)
    }
}
