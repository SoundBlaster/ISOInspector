import Foundation

extension BoxParserRegistry.DefaultParsers {
    @Sendable static func movieFragmentRandomAccess(header: BoxHeader, reader _: RandomAccessReader) throws -> ParsedBoxPayload? {
        guard header.payloadRange.lowerBound <= header.payloadRange.upperBound else { return nil }
        return ParsedBoxPayload()
    }

    @Sendable static func movieFragmentRandomAccessOffset(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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
        guard let mfraSize = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
        fields.append(ParsedBoxPayload.Field(
            name: "mfra_size",
            value: String(mfraSize),
            description: "Size in bytes of the enclosing mfra box",
            byteRange: cursor..<(cursor + 4)
        ))

        let detail = ParsedBoxPayload.MovieFragmentRandomAccessOffsetBox(mfraSize: mfraSize)
        return ParsedBoxPayload(fields: fields, detail: .movieFragmentRandomAccessOffset(detail))
    }

    @Sendable static func trackFragmentRandomAccess(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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
            description: "Track identifier owning the random access table",
            byteRange: cursor..<(cursor + 4)
        ))
        cursor += 4

        guard let lengthSizes = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
        let trafLength = UInt8((lengthSizes >> 4) & 0x03) + 1
        let trunLength = UInt8((lengthSizes >> 2) & 0x03) + 1
        let sampleLength = UInt8(lengthSizes & 0x03) + 1
        fields.append(ParsedBoxPayload.Field(
            name: "length_size_of_traf_num",
            value: String(trafLength),
            description: "Number of bytes used for traf_number values",
            byteRange: cursor..<(cursor + 4)
        ))
        fields.append(ParsedBoxPayload.Field(
            name: "length_size_of_trun_num",
            value: String(trunLength),
            description: "Number of bytes used for trun_number values",
            byteRange: cursor..<(cursor + 4)
        ))
        fields.append(ParsedBoxPayload.Field(
            name: "length_size_of_sample_num",
            value: String(sampleLength),
            description: "Number of bytes used for sample_number values",
            byteRange: cursor..<(cursor + 4)
        ))
        cursor += 4

        guard let entryCount = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
        fields.append(ParsedBoxPayload.Field(
            name: "number_of_entries",
            value: String(entryCount),
            description: "Number of random access entries",
            byteRange: cursor..<(cursor + 4)
        ))
        cursor += 4

        struct RawEntry {
            var time: UInt64
            var moofOffset: UInt64
            var trafNumber: UInt64
            var trunNumber: UInt64
            var sampleNumber: UInt64
        }

        func readVariableLengthUInt(
            _ reader: RandomAccessReader,
            at offset: Int64,
            length: Int,
            end: Int64
        ) throws -> UInt64? {
            guard length > 0, length <= MemoryLayout<UInt64>.size else { return nil }
            guard offset + Int64(length) <= end else { return nil }
            let data = try reader.read(at: offset, count: length)
            guard data.count == length else { return nil }
            var value: UInt64 = 0
            for byte in data {
                value = (value << 8) | UInt64(byte)
            }
            return value
        }

        var rawEntries: [RawEntry] = []
        rawEntries.reserveCapacity(Int(entryCount))

        for index in 0..<Int(entryCount) {
            let time: UInt64
            if fullHeader.version == 1 {
                guard let value = try readUInt64(reader, at: cursor, end: payloadEnd) else { return nil }
                time = value
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].time",
                    value: String(value),
                    description: "Presentation time for the entry",
                    byteRange: cursor..<(cursor + 8)
                ))
                cursor += 8
            } else {
                guard let value32 = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
                time = UInt64(value32)
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].time",
                    value: String(value32),
                    description: "Presentation time for the entry",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4
            }

            let moofOffset: UInt64
            if fullHeader.version == 1 {
                guard let value = try readUInt64(reader, at: cursor, end: payloadEnd) else { return nil }
                moofOffset = value
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].moof_offset",
                    value: String(value),
                    description: "Byte offset of the referenced movie fragment",
                    byteRange: cursor..<(cursor + 8)
                ))
                cursor += 8
            } else {
                guard let value32 = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
                moofOffset = UInt64(value32)
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].moof_offset",
                    value: String(value32),
                    description: "Byte offset of the referenced movie fragment",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4
            }

            guard let trafNumber = try readVariableLengthUInt(reader, at: cursor, length: Int(trafLength), end: payloadEnd) else {
                return nil
            }
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].traf_number",
                value: String(trafNumber),
                description: "1-based index of the track fragment within the movie fragment",
                byteRange: cursor..<(cursor + Int64(trafLength))
            ))
            cursor += Int64(trafLength)

            guard let trunNumber = try readVariableLengthUInt(reader, at: cursor, length: Int(trunLength), end: payloadEnd) else {
                return nil
            }
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].trun_number",
                value: String(trunNumber),
                description: "1-based index of the track run within the track fragment",
                byteRange: cursor..<(cursor + Int64(trunLength))
            ))
            cursor += Int64(trunLength)

            guard let sampleNumber = try readVariableLengthUInt(reader, at: cursor, length: Int(sampleLength), end: payloadEnd) else {
                return nil
            }
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].sample_number",
                value: String(sampleNumber),
                description: "1-based index of the sample within the referenced track run",
                byteRange: cursor..<(cursor + Int64(sampleLength))
            ))
            cursor += Int64(sampleLength)

            rawEntries.append(RawEntry(
                time: time,
                moofOffset: moofOffset,
                trafNumber: trafNumber,
                trunNumber: trunNumber,
                sampleNumber: sampleNumber
            ))

            if cursor > payloadEnd {
                return nil
            }
        }

        let environment = BoxParserRegistry.resolveRandomAccessEnvironment(header: header, reader: reader)

        func findTrackFragment(
            in fragment: BoxParserRegistry.RandomAccessEnvironment.Fragment,
            matching order: UInt64
        ) -> ParsedBoxPayload.TrackFragmentBox? {
            for candidate in fragment.trackFragments {
                let candidateOrder = UInt64(candidate.order)
                if candidateOrder == order {
                    return candidate.detail
                }
            }
            return nil
        }

        func findRun(
            in trackFragment: ParsedBoxPayload.TrackFragmentBox,
            matching index: UInt64
        ) -> ParsedBoxPayload.TrackRunBox? {
            for (position, run) in trackFragment.runs.enumerated() {
                if let runIndex = run.runIndex {
                    if UInt64(runIndex) + 1 == index { return run }
                } else if UInt64(position + 1) == index {
                    return run
                }
            }
            return nil
        }

        let entries: [ParsedBoxPayload.TrackFragmentRandomAccessBox.Entry] = rawEntries.enumerated().map { offset, raw in
            let fragment = environment.fragmentsByMoofOffset[raw.moofOffset]
            let trackFragment = fragment.flatMap { findTrackFragment(in: $0, matching: raw.trafNumber) }
            let run = trackFragment.flatMap { findRun(in: $0, matching: raw.trunNumber) }
            let sample = run?.entries.first { UInt64($0.index) == raw.sampleNumber }

            let resolvedTrackID = trackFragment?.trackID ?? run?.trackID
            let resolvedDescriptionIndex = trackFragment?.sampleDescriptionIndex ?? run?.sampleDescriptionIndex
            let resolvedRunIndex: UInt32? = {
                if let runIndex = run?.runIndex { return runIndex }
                if let trackFragment, let run = run,
                   let position = trackFragment.runs.firstIndex(where: { $0 == run }) {
                    return UInt32(position)
                }
                return nil
            }()

            return ParsedBoxPayload.TrackFragmentRandomAccessBox.Entry(
                index: UInt32(offset + 1),
                time: raw.time,
                moofOffset: raw.moofOffset,
                trafNumber: raw.trafNumber,
                trunNumber: raw.trunNumber,
                sampleNumber: raw.sampleNumber,
                fragmentSequenceNumber: fragment?.sequenceNumber,
                trackID: resolvedTrackID,
                sampleDescriptionIndex: resolvedDescriptionIndex,
                runIndex: resolvedRunIndex,
                firstSampleGlobalIndex: run?.firstSampleGlobalIndex,
                resolvedDecodeTime: sample?.decodeTime,
                resolvedPresentationTime: sample?.presentationTime,
                resolvedDataOffset: sample?.dataOffset,
                resolvedSampleSize: sample?.sampleSize,
                resolvedSampleFlags: sample?.sampleFlags
            )
        }

        let detail = ParsedBoxPayload.TrackFragmentRandomAccessBox(
            version: fullHeader.version,
            flags: fullHeader.flags,
            trackID: trackID,
            trafNumberLength: trafLength,
            trunNumberLength: trunLength,
            sampleNumberLength: sampleLength,
            entryCount: entryCount,
            entries: entries
        )

        return ParsedBoxPayload(fields: fields, detail: .trackFragmentRandomAccess(detail))
    }
}
