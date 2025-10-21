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
}
