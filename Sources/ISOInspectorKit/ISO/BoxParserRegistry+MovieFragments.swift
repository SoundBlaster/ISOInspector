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

    static func trackFragmentDecodeTime(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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
        let is64Bit = fullHeader.version != 0

        if is64Bit {
            guard let decodeTime = try readUInt64(reader, at: cursor, end: payloadEnd) else { return nil }
            let range = cursor..<(cursor + 8)
            fields.append(ParsedBoxPayload.Field(
                name: "base_media_decode_time",
                value: String(decodeTime),
                description: "Base media decode time",
                byteRange: range
            ))

            let detail = ParsedBoxPayload.Detail.trackFragmentDecodeTime(
                ParsedBoxPayload.TrackFragmentDecodeTimeBox(
                    version: fullHeader.version,
                    flags: fullHeader.flags,
                    baseMediaDecodeTime: decodeTime,
                    baseMediaDecodeTimeIs64Bit: true
                )
            )
            return ParsedBoxPayload(fields: fields, detail: detail)
        } else {
            guard let decodeTime = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
            let range = cursor..<(cursor + 4)
            fields.append(ParsedBoxPayload.Field(
                name: "base_media_decode_time",
                value: String(decodeTime),
                description: "Base media decode time",
                byteRange: range
            ))

            let detail = ParsedBoxPayload.Detail.trackFragmentDecodeTime(
                ParsedBoxPayload.TrackFragmentDecodeTimeBox(
                    version: fullHeader.version,
                    flags: fullHeader.flags,
                    baseMediaDecodeTime: UInt64(decodeTime),
                    baseMediaDecodeTimeIs64Bit: false
                )
            )
            return ParsedBoxPayload(fields: fields, detail: detail)
        }
    }

    static func trackRun(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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
        guard let sampleCount = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
        fields.append(ParsedBoxPayload.Field(
            name: "sample_count",
            value: String(sampleCount),
            description: "Number of samples in this run",
            byteRange: cursor..<(cursor + 4)
        ))
        cursor += 4

        var dataOffset: Int32?
        if fullHeader.flags & 0x000001 != 0 {
            guard let offset = try readInt32(reader, at: cursor, end: payloadEnd) else { return nil }
            dataOffset = offset
            fields.append(ParsedBoxPayload.Field(
                name: "data_offset",
                value: String(offset),
                description: "Offset from base data position",
                byteRange: cursor..<(cursor + 4)
            ))
            cursor += 4
        }

        var firstSampleFlags: UInt32?
        if fullHeader.flags & 0x000004 != 0 {
            guard let flags = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
            firstSampleFlags = flags
            fields.append(ParsedBoxPayload.Field(
                name: "first_sample_flags",
                value: String(format: "0x%08X", flags),
                description: "Flags applied to the first sample",
                byteRange: cursor..<(cursor + 4)
            ))
            cursor += 4
        }

        let hasSampleDurations = (fullHeader.flags & 0x000100) != 0
        let hasSampleSizes = (fullHeader.flags & 0x000200) != 0
        let hasSampleFlags = (fullHeader.flags & 0x000400) != 0
        let hasCompositionOffsets = (fullHeader.flags & 0x000800) != 0

        let entryCount = Int(sampleCount)
        var sampleDurations: [UInt32?] = Array(repeating: nil, count: entryCount)
        var sampleSizes: [UInt32?] = Array(repeating: nil, count: entryCount)
        var sampleFlags: [UInt32?] = Array(repeating: nil, count: entryCount)
        var compositionOffsets: [Int32?] = Array(repeating: nil, count: entryCount)
        var entryRanges: [Range<Int64>?] = Array(repeating: nil, count: entryCount)

        for index in 0..<entryCount {
            let entryStart = cursor
            var entryEnd = cursor
            var recordedBytes = false

            if hasSampleDurations {
                guard let duration = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
                sampleDurations[index] = duration
                let range = cursor..<(cursor + 4)
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].sample_duration",
                    value: String(duration),
                    description: "Sample duration",
                    byteRange: range
                ))
                cursor += 4
                entryEnd = cursor
                recordedBytes = true
            }

            if hasSampleSizes {
                guard let size = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
                sampleSizes[index] = size
                let range = cursor..<(cursor + 4)
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].sample_size",
                    value: String(size),
                    description: "Sample size",
                    byteRange: range
                ))
                cursor += 4
                entryEnd = cursor
                recordedBytes = true
            }

            if hasSampleFlags {
                guard let flags = try readUInt32(reader, at: cursor, end: payloadEnd) else { return nil }
                sampleFlags[index] = flags
                let range = cursor..<(cursor + 4)
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].sample_flags",
                    value: String(format: "0x%08X", flags),
                    description: "Per-sample flags",
                    byteRange: range
                ))
                cursor += 4
                entryEnd = cursor
                recordedBytes = true
            }

            if hasCompositionOffsets {
                guard let offset = try readInt32(reader, at: cursor, end: payloadEnd) else { return nil }
                compositionOffsets[index] = offset
                let range = cursor..<(cursor + 4)
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].sample_composition_time_offset",
                    value: String(offset),
                    description: "Composition time offset",
                    byteRange: range
                ))
                cursor += 4
                entryEnd = cursor
                recordedBytes = true
            }

            if recordedBytes {
                entryRanges[index] = entryStart..<entryEnd
            }
        }

        let environment = BoxParserRegistry.resolveFragmentEnvironment(header: header, reader: reader)

        func resolvedDataOffset(
            base: UInt64?,
            cursor: UInt64?,
            delta: Int32?
        ) -> UInt64? {
            if let base, let delta {
                if base > UInt64(Int64.max) { return nil }
                let baseValue = Int64(base)
                let combined = baseValue + Int64(delta)
                guard combined >= 0 else { return nil }
                return UInt64(combined)
            }
            if let cursor, let delta {
                if cursor > UInt64(Int64.max) { return nil }
                let baseValue = Int64(cursor)
                let combined = baseValue + Int64(delta)
                guard combined >= 0 else { return nil }
                return UInt64(combined)
            }
            if let cursor {
                return cursor
            }
            if let delta, delta >= 0 {
                return UInt64(delta)
            }
            return nil
        }

        var entries: [ParsedBoxPayload.TrackRunBox.Entry] = []
        entries.reserveCapacity(entryCount)

        let startDecodeTime = environment.nextDecodeTime ?? environment.baseDecodeTime
        var decodeCursor = startDecodeTime

        var startPresentationTime: Int64?
        var endPresentationTime: Int64?

        var totalDuration: UInt64 = 0
        var durationKnown = true
        var totalSize: UInt64 = 0
        var sizeKnown = true

        var currentDataOffset = resolvedDataOffset(
            base: environment.baseDataOffset,
            cursor: environment.dataCursor,
            delta: dataOffset
        )
        let startDataOffset = currentDataOffset

        func int64(from value: UInt64?) -> Int64? {
            guard let value, value <= UInt64(Int64.max) else { return nil }
            return Int64(value)
        }

        for index in 0..<entryCount {
            let resolvedDuration = sampleDurations[index] ?? environment.defaultSampleDuration
            let resolvedSize = sampleSizes[index] ?? environment.defaultSampleSize
            var resolvedFlags = sampleFlags[index]
            if resolvedFlags == nil {
                if index == 0, let first = firstSampleFlags {
                    resolvedFlags = first
                } else {
                    resolvedFlags = environment.defaultSampleFlags
                }
            }
            let resolvedOffset = compositionOffsets[index]

            let entryDecodeTime = decodeCursor
            let entryPresentation: Int64?
            if let decodeValue = decodeCursor, let decodeInt = int64(from: decodeValue) {
                if let offset = resolvedOffset {
                    let (presentation, overflow) = decodeInt.addingReportingOverflow(Int64(offset))
                    entryPresentation = overflow ? nil : presentation
                } else {
                    entryPresentation = decodeInt
                }
            } else {
                entryPresentation = nil
            }

            if startPresentationTime == nil, let presentation = entryPresentation {
                startPresentationTime = presentation
            }
            if let presentation = entryPresentation {
                endPresentationTime = presentation
            }

            if let duration = resolvedDuration, durationKnown {
                let (newTotal, overflow) = totalDuration.addingReportingOverflow(UInt64(duration))
                if overflow {
                    durationKnown = false
                } else {
                    totalDuration = newTotal
                }
            } else if resolvedDuration == nil {
                durationKnown = false
            }

            if let size = resolvedSize, sizeKnown {
                let (newSize, overflow) = totalSize.addingReportingOverflow(UInt64(size))
                if overflow {
                    sizeKnown = false
                } else {
                    totalSize = newSize
                }
            } else if resolvedSize == nil {
                sizeKnown = false
            }

            let entryDataOffset = currentDataOffset
            if let size = resolvedSize, let offset = currentDataOffset {
                let (nextOffset, overflow) = offset.addingReportingOverflow(UInt64(size))
                if overflow {
                    currentDataOffset = nil
                } else {
                    currentDataOffset = nextOffset
                }
            } else if resolvedSize == nil {
                currentDataOffset = nil
            }

            if let duration = resolvedDuration, let decode = decodeCursor {
                let (nextDecode, overflow) = decode.addingReportingOverflow(UInt64(duration))
                if overflow {
                    decodeCursor = nil
                } else {
                    decodeCursor = nextDecode
                }
            } else {
                decodeCursor = nil
            }

            entries.append(ParsedBoxPayload.TrackRunBox.Entry(
                index: UInt32(index + 1),
                decodeTime: entryDecodeTime,
                presentationTime: entryPresentation,
                sampleDuration: resolvedDuration,
                sampleSize: resolvedSize,
                sampleFlags: resolvedFlags,
                sampleCompositionTimeOffset: resolvedOffset,
                dataOffset: entryDataOffset,
                byteRange: entryRanges[index]
            ))
        }

        if startPresentationTime == nil {
            startPresentationTime = int64(from: startDecodeTime)
        }
        if endPresentationTime == nil {
            endPresentationTime = int64(from: decodeCursor)
        }

        let runDetail = ParsedBoxPayload.TrackRunBox(
            version: fullHeader.version,
            flags: fullHeader.flags,
            sampleCount: sampleCount,
            dataOffset: dataOffset,
            firstSampleFlags: firstSampleFlags,
            entries: entries,
            totalSampleDuration: durationKnown ? totalDuration : nil,
            totalSampleSize: sizeKnown ? totalSize : nil,
            startDecodeTime: startDecodeTime,
            endDecodeTime: decodeCursor,
            startPresentationTime: startPresentationTime,
            endPresentationTime: endPresentationTime,
            startDataOffset: startDataOffset,
            endDataOffset: currentDataOffset,
            trackID: environment.trackID,
            sampleDescriptionIndex: environment.sampleDescriptionIndex,
            runIndex: environment.runIndex,
            firstSampleGlobalIndex: environment.nextSampleNumber
        )

        return ParsedBoxPayload(fields: fields, detail: .trackRun(runDetail))
    }

    static func trackFragment(header: BoxHeader, reader _: RandomAccessReader) throws -> ParsedBoxPayload? {
        guard header.payloadRange.lowerBound <= header.payloadRange.upperBound else { return nil }
        return ParsedBoxPayload()
    }
}
