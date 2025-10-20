import Foundation

extension BoxParserRegistry.DefaultParsers {
    static func editList(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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
        guard cursor + 4 <= end else { return nil }
        guard let entryCountRaw = try readUInt32(reader, at: cursor, end: end) else { return nil }
        fields.append(ParsedBoxPayload.Field(
            name: "entry_count",
            value: String(entryCountRaw),
            description: "Number of edit entries",
            byteRange: cursor..<(cursor + 4)
        ))
        cursor += 4

        guard let entryCount = Int(exactly: entryCountRaw) else { return nil }

        let environment = BoxParserRegistry.resolveEditListEnvironment(header: header, reader: reader)
        let movieTimescale = environment.movieTimescale
        let mediaTimescale = environment.mediaTimescale

        var presentationCursor: UInt64 = 0
        var entries: [ParsedBoxPayload.EditListBox.Entry] = []
        entries.reserveCapacity(entryCount)

        for index in 0..<entryCount {
            let segmentRange: Range<Int64>
            let segmentDuration: UInt64
            if fullHeader.version == 1 {
                segmentRange = cursor..<(cursor + 8)
                guard let duration = try readUInt64(reader, at: cursor, end: end) else { return nil }
                segmentDuration = duration
                cursor += 8
            } else {
                segmentRange = cursor..<(cursor + 4)
                guard let duration = try readUInt32(reader, at: cursor, end: end) else { return nil }
                segmentDuration = UInt64(duration)
                cursor += 4
            }

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].segment_duration",
                value: String(segmentDuration),
                description: "Edit segment duration (movie timescale ticks)",
                byteRange: segmentRange
            ))

            let segmentSeconds = normalizedSeconds(for: segmentDuration, timescale: movieTimescale)
            if let segmentSeconds {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].segment_duration_seconds",
                    value: formatSeconds(segmentSeconds),
                    description: "Edit segment duration expressed in seconds",
                    byteRange: nil
                ))
            }

            let mediaRange: Range<Int64>
            let mediaTime: Int64
            if fullHeader.version == 1 {
                mediaRange = cursor..<(cursor + 8)
                guard let time = try readInt64(reader, at: cursor, end: end) else { return nil }
                mediaTime = time
                cursor += 8
            } else {
                mediaRange = cursor..<(cursor + 4)
                guard let time = try readInt32(reader, at: cursor, end: end) else { return nil }
                mediaTime = Int64(time)
                cursor += 4
            }

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].media_time",
                value: String(mediaTime),
                description: "Starting media time (track timescale ticks; -1 for empty)",
                byteRange: mediaRange
            ))

            let mediaSeconds = normalizedSeconds(forSigned: mediaTime, timescale: mediaTimescale)
            if mediaTime != -1, let mediaSeconds {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].media_time_seconds",
                    value: formatSeconds(mediaSeconds),
                    description: "Starting media time expressed in seconds",
                    byteRange: nil
                ))
            }

            let rateIntegerRange = cursor..<(cursor + 2)
            guard let mediaRateInteger = try readInt16(reader, at: cursor, end: end) else { return nil }
            cursor += 2
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].media_rate_integer",
                value: String(mediaRateInteger),
                description: "Playback rate integer component",
                byteRange: rateIntegerRange
            ))

            let rateFractionRange = cursor..<(cursor + 2)
            guard let mediaRateFraction = try readUInt16(reader, at: cursor, end: end) else { return nil }
            cursor += 2
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].media_rate_fraction",
                value: String(mediaRateFraction),
                description: "Playback rate fractional component",
                byteRange: rateFractionRange
            ))

            let mediaRate = Double(mediaRateInteger) + Double(mediaRateFraction) / 65_536.0
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].media_rate",
                value: formatMediaRate(mediaRate),
                description: "Playback rate (integer + fraction/65536)",
                byteRange: nil
            ))

            let isEmptyEdit = mediaTime == -1
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].is_empty_edit",
                value: boolString(isEmptyEdit),
                description: "Indicates whether the edit inserts silence/black",
                byteRange: nil
            ))

            let presentationStart = presentationCursor
            let presentationEnd = presentationCursor &+ segmentDuration

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].presentation_start",
                value: String(presentationStart),
                description: "Cumulative movie timeline start tick",
                byteRange: nil
            ))

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].presentation_end",
                value: String(presentationEnd),
                description: "Cumulative movie timeline end tick",
                byteRange: nil
            ))

            let presentationStartSeconds = normalizedSeconds(for: presentationStart, timescale: movieTimescale)
            if let presentationStartSeconds {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].presentation_start_seconds",
                    value: formatSeconds(presentationStartSeconds),
                    description: "Cumulative movie timeline start in seconds",
                    byteRange: nil
                ))
            }

            let presentationEndSeconds = normalizedSeconds(for: presentationEnd, timescale: movieTimescale)
            if let presentationEndSeconds {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].presentation_end_seconds",
                    value: formatSeconds(presentationEndSeconds),
                    description: "Cumulative movie timeline end in seconds",
                    byteRange: nil
                ))
            }

            let entry = ParsedBoxPayload.EditListBox.Entry(
                index: UInt32(index),
                segmentDuration: segmentDuration,
                mediaTime: mediaTime,
                mediaRateInteger: mediaRateInteger,
                mediaRateFraction: mediaRateFraction,
                mediaRate: mediaRate,
                segmentDurationSeconds: segmentSeconds,
                mediaTimeSeconds: isEmptyEdit ? nil : mediaSeconds,
                presentationStart: presentationStart,
                presentationEnd: presentationEnd,
                presentationStartSeconds: presentationStartSeconds,
                presentationEndSeconds: presentationEndSeconds,
                isEmptyEdit: isEmptyEdit
            )

            entries.append(entry)
            presentationCursor = presentationEnd
        }

        let detail = ParsedBoxPayload.EditListBox(
            version: fullHeader.version,
            flags: fullHeader.flags,
            entryCount: entryCountRaw,
            movieTimescale: movieTimescale,
            mediaTimescale: mediaTimescale,
            entries: entries
        )

        return ParsedBoxPayload(fields: fields, detail: .editList(detail))
    }
}
