import Foundation

extension BoxParserRegistry.DefaultParsers {
    @Sendable static func sampleToChunk(header: BoxHeader, reader: RandomAccessReader) throws
        -> ParsedBoxPayload? {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else {
            return nil
        }

        var fields: [ParsedBoxPayload.Field] = []
        let start = header.payloadRange.lowerBound
        let end = header.payloadRange.upperBound

        fields.append(
            ParsedBoxPayload.Field(
                name: "version",
                value: String(fullHeader.version),
                description: "Structure version",
                byteRange: start..<(start + 1)
            ))

        fields.append(
            ParsedBoxPayload.Field(
                name: "flags",
                value: String(format: "0x%06X", fullHeader.flags),
                description: "Bit flags",
                byteRange: (start + 1)..<(start + 4)
            ))

        var cursor = fullHeader.contentStart
        let entryCountOffset = cursor
        let entryCountEndResult = cursor.addingReportingOverflow(4)
        guard !entryCountEndResult.overflow else { return nil }
        let entryCountEnd = entryCountEndResult.partialValue
        guard let entryCount = try readUInt32(reader, at: cursor, end: end) else { return nil }
        fields.append(
            ParsedBoxPayload.Field(
                name: "entry_count",
                value: String(entryCount),
                description: "Number of sample-to-chunk table entries",
                byteRange: entryCountOffset..<entryCountEnd
            ))
        cursor = entryCountEnd

        var entries: [ParsedBoxPayload.SampleToChunkBox.Entry] = []
        var index: UInt32 = 0

        func appendTruncationStatus(_ missingField: String) {
            let range: Range<Int64>?
            if cursor < end {
                range = cursor..<end
            } else {
                range = nil
            }
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].status",
                    value: "truncated",
                    description: "Entry truncated before \(missingField) field",
                    byteRange: range
                ))
        }

        while index < entryCount, cursor < end {
            let entryStart = cursor

            let firstChunkEndResult = cursor.addingReportingOverflow(4)
            guard !firstChunkEndResult.overflow else {
                appendTruncationStatus("first_chunk")
                break
            }
            let firstChunkEnd = firstChunkEndResult.partialValue
            guard firstChunkEnd <= end,
                let firstChunk = try readUInt32(reader, at: cursor, end: end)
            else {
                appendTruncationStatus("first_chunk")
                break
            }
            let firstChunkRange = cursor..<firstChunkEnd
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].first_chunk",
                    value: String(firstChunk),
                    description: "1-based index of the first chunk for this entry",
                    byteRange: firstChunkRange
                ))
            cursor = firstChunkEnd

            let samplesPerChunkEndResult = cursor.addingReportingOverflow(4)
            guard !samplesPerChunkEndResult.overflow else {
                appendTruncationStatus("samples_per_chunk")
                break
            }
            let samplesPerChunkEnd = samplesPerChunkEndResult.partialValue
            guard samplesPerChunkEnd <= end,
                let samplesPerChunk = try readUInt32(reader, at: cursor, end: end)
            else {
                appendTruncationStatus("samples_per_chunk")
                break
            }
            let samplesRange = cursor..<samplesPerChunkEnd
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].samples_per_chunk",
                    value: String(samplesPerChunk),
                    description: "Number of samples in each chunk",
                    byteRange: samplesRange
                ))
            cursor = samplesPerChunkEnd

            let descriptionIndexEndResult = cursor.addingReportingOverflow(4)
            guard !descriptionIndexEndResult.overflow else {
                appendTruncationStatus("sample_description_index")
                break
            }
            let descriptionIndexEnd = descriptionIndexEndResult.partialValue
            guard descriptionIndexEnd <= end,
                let sampleDescriptionIndex = try readUInt32(reader, at: cursor, end: end)
            else {
                appendTruncationStatus("sample_description_index")
                break
            }
            let descriptionRange = cursor..<descriptionIndexEnd
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].sample_description_index",
                    value: String(sampleDescriptionIndex),
                    description: "Index into the sample description table",
                    byteRange: descriptionRange
                ))
            cursor = descriptionIndexEnd

            let entryRange = entryStart..<cursor
            entries.append(
                ParsedBoxPayload.SampleToChunkBox.Entry(
                    firstChunk: firstChunk,
                    samplesPerChunk: samplesPerChunk,
                    sampleDescriptionIndex: sampleDescriptionIndex,
                    byteRange: entryRange
                ))

            if cursor <= entryStart {
                break
            }

            index += 1
        }

        let detail: ParsedBoxPayload.Detail?
        if fullHeader.version == 0, fullHeader.flags == 0, UInt32(entries.count) == entryCount {
            detail = .sampleToChunk(
                ParsedBoxPayload.SampleToChunkBox(
                    version: fullHeader.version,
                    flags: fullHeader.flags,
                    entries: entries
                ))
        } else {
            detail = nil
        }

        return ParsedBoxPayload(fields: fields, detail: detail)
    }

    @Sendable static func decodingTimeToSample(header: BoxHeader, reader: RandomAccessReader) throws
        -> ParsedBoxPayload? {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else {
            return nil
        }

        var fields: [ParsedBoxPayload.Field] = []
        let start = header.payloadRange.lowerBound
        let end = header.payloadRange.upperBound

        fields.append(
            ParsedBoxPayload.Field(
                name: "version",
                value: String(fullHeader.version),
                description: "Structure version",
                byteRange: start..<(start + 1)
            ))

        fields.append(
            ParsedBoxPayload.Field(
                name: "flags",
                value: String(format: "0x%06X", fullHeader.flags),
                description: "Bit flags",
                byteRange: (start + 1)..<(start + 4)
            ))

        var cursor = fullHeader.contentStart

        let countEndResult = cursor.addingReportingOverflow(4)
        guard !countEndResult.overflow else { return nil }
        let countEnd = countEndResult.partialValue
        guard countEnd <= end,
            let entryCount = try readUInt32(reader, at: cursor, end: end)
        else { return nil }
        fields.append(
            ParsedBoxPayload.Field(
                name: "entry_count",
                value: String(entryCount),
                description: "Number of decoding time entries",
                byteRange: cursor..<countEnd
            ))
        cursor = countEnd

        var entries: [ParsedBoxPayload.DecodingTimeToSampleBox.Entry] = []
        var index: UInt32 = 0

        func appendTruncationStatus(_ missingField: String) {
            let range: Range<Int64>?
            if cursor < end {
                range = cursor..<end
            } else {
                range = nil
            }
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].status",
                    value: "truncated",
                    description: "Entry truncated before \(missingField) field",
                    byteRange: range
                ))
        }

        while index < entryCount, cursor < end {
            let entryStart = cursor

            let sampleCountEndResult = cursor.addingReportingOverflow(4)
            guard !sampleCountEndResult.overflow else {
                appendTruncationStatus("sample_count")
                break
            }
            let sampleCountEnd = sampleCountEndResult.partialValue
            guard sampleCountEnd <= end,
                let sampleCount = try readUInt32(reader, at: cursor, end: end)
            else {
                appendTruncationStatus("sample_count")
                break
            }
            let sampleCountRange = cursor..<sampleCountEnd
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].sample_count",
                    value: String(sampleCount),
                    description: "Number of consecutive samples using this delta",
                    byteRange: sampleCountRange
                ))
            cursor = sampleCountEnd

            let sampleDeltaEndResult = cursor.addingReportingOverflow(4)
            guard !sampleDeltaEndResult.overflow else {
                appendTruncationStatus("sample_delta")
                break
            }
            let sampleDeltaEnd = sampleDeltaEndResult.partialValue
            guard sampleDeltaEnd <= end,
                let sampleDelta = try readUInt32(reader, at: cursor, end: end)
            else {
                appendTruncationStatus("sample_delta")
                break
            }
            let sampleDeltaRange = cursor..<sampleDeltaEnd
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].sample_delta",
                    value: String(sampleDelta),
                    description: "Decode time delta applied to each sample",
                    byteRange: sampleDeltaRange
                ))
            cursor = sampleDeltaEnd

            let entryRange = entryStart..<cursor
            entries.append(
                ParsedBoxPayload.DecodingTimeToSampleBox.Entry(
                    index: index,
                    sampleCount: sampleCount,
                    sampleDelta: sampleDelta,
                    byteRange: entryRange
                ))

            if cursor <= entryStart {
                break
            }

            index += 1
        }

        let detail: ParsedBoxPayload.Detail?
        if UInt32(entries.count) == entryCount {
            detail = .decodingTimeToSample(
                ParsedBoxPayload.DecodingTimeToSampleBox(
                    version: fullHeader.version,
                    flags: fullHeader.flags,
                    entryCount: entryCount,
                    entries: entries
                ))
        } else {
            detail = nil
        }

        return ParsedBoxPayload(fields: fields, detail: detail)
    }

    @Sendable static func compositionOffset(header: BoxHeader, reader: RandomAccessReader) throws
        -> ParsedBoxPayload? {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else {
            return nil
        }

        var fields: [ParsedBoxPayload.Field] = []
        let start = header.payloadRange.lowerBound
        let end = header.payloadRange.upperBound

        fields.append(
            ParsedBoxPayload.Field(
                name: "version",
                value: String(fullHeader.version),
                description: "Structure version",
                byteRange: start..<(start + 1)
            ))

        fields.append(
            ParsedBoxPayload.Field(
                name: "flags",
                value: String(format: "0x%06X", fullHeader.flags),
                description: "Bit flags",
                byteRange: (start + 1)..<(start + 4)
            ))

        var cursor = fullHeader.contentStart

        let countEndResult = cursor.addingReportingOverflow(4)
        guard !countEndResult.overflow else { return nil }
        let countEnd = countEndResult.partialValue
        guard countEnd <= end,
            let entryCount = try readUInt32(reader, at: cursor, end: end)
        else { return nil }
        fields.append(
            ParsedBoxPayload.Field(
                name: "entry_count",
                value: String(entryCount),
                description: "Number of composition offset entries",
                byteRange: cursor..<countEnd
            ))
        cursor = countEnd

        var entries: [ParsedBoxPayload.CompositionOffsetBox.Entry] = []
        var index: UInt32 = 0

        func appendTruncationStatus(_ missingField: String) {
            let range: Range<Int64>?
            if cursor < end {
                range = cursor..<end
            } else {
                range = nil
            }
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].status",
                    value: "truncated",
                    description: "Entry truncated before \(missingField) field",
                    byteRange: range
                ))
        }

        while index < entryCount, cursor < end {
            let entryStart = cursor

            let sampleCountEndResult = cursor.addingReportingOverflow(4)
            guard !sampleCountEndResult.overflow else {
                appendTruncationStatus("sample_count")
                break
            }
            let sampleCountEnd = sampleCountEndResult.partialValue
            guard sampleCountEnd <= end,
                let sampleCount = try readUInt32(reader, at: cursor, end: end)
            else {
                appendTruncationStatus("sample_count")
                break
            }
            let sampleCountRange = cursor..<sampleCountEnd
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].sample_count",
                    value: String(sampleCount),
                    description: "Number of consecutive samples using this offset",
                    byteRange: sampleCountRange
                ))
            cursor = sampleCountEnd

            let offsetEndResult = cursor.addingReportingOverflow(4)
            guard !offsetEndResult.overflow else {
                appendTruncationStatus("sample_offset")
                break
            }
            let offsetEnd = offsetEndResult.partialValue
            guard offsetEnd <= end else {
                appendTruncationStatus("sample_offset")
                break
            }

            let offsetRange = cursor..<offsetEnd
            let offsetValue: Int32?
            if fullHeader.version == 0 {
                guard let raw = try readUInt32(reader, at: cursor, end: end) else {
                    appendTruncationStatus("sample_offset")
                    break
                }
                fields.append(
                    ParsedBoxPayload.Field(
                        name: "entries[\(index)].sample_offset",
                        value: String(raw),
                        description: "Composition time offset",
                        byteRange: offsetRange
                    ))
                offsetValue = Int32(bitPattern: raw)
            } else {
                guard let signed = try readInt32(reader, at: cursor, end: end) else {
                    appendTruncationStatus("sample_offset")
                    break
                }
                fields.append(
                    ParsedBoxPayload.Field(
                        name: "entries[\(index)].sample_offset",
                        value: String(signed),
                        description: "Composition time offset",
                        byteRange: offsetRange
                    ))
                offsetValue = signed
            }
            cursor = offsetEnd

            guard let sampleOffset = offsetValue else {
                appendTruncationStatus("sample_offset")
                break
            }

            let entryRange = entryStart..<cursor
            entries.append(
                ParsedBoxPayload.CompositionOffsetBox.Entry(
                    index: index,
                    sampleCount: sampleCount,
                    sampleOffset: sampleOffset,
                    byteRange: entryRange
                ))

            if cursor <= entryStart {
                break
            }

            index += 1
        }

        let detail: ParsedBoxPayload.Detail?
        if UInt32(entries.count) == entryCount {
            detail = .compositionOffset(
                ParsedBoxPayload.CompositionOffsetBox(
                    version: fullHeader.version,
                    flags: fullHeader.flags,
                    entryCount: entryCount,
                    entries: entries
                ))
        } else {
            detail = nil
        }

        return ParsedBoxPayload(fields: fields, detail: detail)
    }

    @Sendable static func chunkOffset32(header: BoxHeader, reader: RandomAccessReader) throws
        -> ParsedBoxPayload? {
        try parseChunkOffsets(header: header, reader: reader, width: .bits32)
    }

    @Sendable static func chunkOffset64(header: BoxHeader, reader: RandomAccessReader) throws
        -> ParsedBoxPayload? {
        try parseChunkOffsets(header: header, reader: reader, width: .bits64)
    }

    @Sendable private static func parseChunkOffsets(
        header: BoxHeader,
        reader: RandomAccessReader,
        width: ParsedBoxPayload.ChunkOffsetBox.Width
    ) throws -> ParsedBoxPayload? {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else {
            return nil
        }

        var fields: [ParsedBoxPayload.Field] = []
        let start = header.payloadRange.lowerBound
        let end = header.payloadRange.upperBound

        fields.append(
            ParsedBoxPayload.Field(
                name: "version",
                value: String(fullHeader.version),
                description: "Structure version",
                byteRange: start..<(start + 1)
            ))

        fields.append(
            ParsedBoxPayload.Field(
                name: "flags",
                value: String(format: "0x%06X", fullHeader.flags),
                description: "Bit flags",
                byteRange: (start + 1)..<(start + 4)
            ))

        var cursor = fullHeader.contentStart

        let countEndResult = cursor.addingReportingOverflow(4)
        guard !countEndResult.overflow else { return nil }
        let countEnd = countEndResult.partialValue
        guard countEnd <= end,
            let entryCount = try readUInt32(reader, at: cursor, end: end)
        else { return nil }
        fields.append(
            ParsedBoxPayload.Field(
                name: "entry_count",
                value: String(entryCount),
                description: "Number of chunk offsets",
                byteRange: cursor..<countEnd
            ))
        cursor = countEnd

        var entries: [ParsedBoxPayload.ChunkOffsetBox.Entry] = []

        func appendTruncationStatus(_ index: UInt32) {
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].status",
                    value: "truncated",
                    description: "Entry truncated before chunk offset completed",
                    byteRange: nil
                ))
        }

        let widthBytes: Int64 = width == .bits32 ? 4 : 8
        var index: UInt32 = 0
        while index < entryCount {
            guard cursor < end else {
                appendTruncationStatus(index)
                break
            }

            let entryStart = cursor
            let entryEndResult = cursor.addingReportingOverflow(widthBytes)
            guard !entryEndResult.overflow else {
                appendTruncationStatus(index)
                break
            }
            let entryEnd = entryEndResult.partialValue
            guard entryEnd <= end else {
                appendTruncationStatus(index)
                break
            }

            let offsetValue: UInt64?
            switch width {
            case .bits32:
                offsetValue = try readUInt32(reader, at: cursor, end: end).map(UInt64.init)
            case .bits64:
                offsetValue = try readUInt64(reader, at: cursor, end: end)
            }

            guard let offset = offsetValue else {
                appendTruncationStatus(index)
                break
            }

            let entryRange = entryStart..<entryEnd
            let hexDigits = width == .bits32 ? 8 : 16
            let hexFormat = "0x%0\(hexDigits)llX"
            let hexString = String(format: hexFormat, offset)
            let formattedValue = "\(offset) (\(hexString))"
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].chunk_offset",
                    value: formattedValue,
                    description: width == .bits32
                        ? "Chunk offset (32-bit)" : "Chunk offset (64-bit)",
                    byteRange: entryRange
                ))

            entries.append(
                ParsedBoxPayload.ChunkOffsetBox.Entry(
                    index: index,
                    offset: offset,
                    byteRange: entryRange
                ))

            cursor = entryEnd
            if cursor <= entryStart {
                break
            }

            index += 1
        }

        let detail: ParsedBoxPayload.Detail?
        if UInt32(entries.count) == entryCount {
            detail = .chunkOffset(
                ParsedBoxPayload.ChunkOffsetBox(
                    version: fullHeader.version,
                    flags: fullHeader.flags,
                    entryCount: entryCount,
                    width: width,
                    entries: entries
                ))
        } else {
            detail = nil
        }

        return ParsedBoxPayload(fields: fields, detail: detail)
    }

    @Sendable static func syncSampleTable(header: BoxHeader, reader: RandomAccessReader) throws
        -> ParsedBoxPayload? {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else {
            return nil
        }

        var fields: [ParsedBoxPayload.Field] = []
        let start = header.payloadRange.lowerBound
        let end = header.payloadRange.upperBound

        fields.append(
            ParsedBoxPayload.Field(
                name: "version",
                value: String(fullHeader.version),
                description: "Structure version",
                byteRange: start..<(start + 1)
            ))

        fields.append(
            ParsedBoxPayload.Field(
                name: "flags",
                value: String(format: "0x%06X", fullHeader.flags),
                description: "Bit flags",
                byteRange: (start + 1)..<(start + 4)
            ))

        var cursor = fullHeader.contentStart

        let countEndResult = cursor.addingReportingOverflow(4)
        guard !countEndResult.overflow else { return nil }
        let countEnd = countEndResult.partialValue
        guard countEnd <= end,
            let entryCount = try readUInt32(reader, at: cursor, end: end)
        else { return nil }
        let countRange = cursor..<countEnd
        fields.append(
            ParsedBoxPayload.Field(
                name: "entry_count",
                value: String(entryCount),
                description: "Number of sync sample entries",
                byteRange: countRange
            ))
        cursor = countEnd

        var entries: [ParsedBoxPayload.SyncSampleTableBox.Entry] = []

        func appendTruncationStatus(_ entryIndex: UInt32) {
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].status",
                    value: "truncated",
                    description: "Entry truncated before sample_number field completed",
                    byteRange: nil
                ))
        }

        var index: UInt32 = 0
        while index < entryCount {
            guard cursor < end else {
                appendTruncationStatus(index)
                break
            }
            let entryStart = cursor
            let entryEndResult = cursor.addingReportingOverflow(4)
            guard !entryEndResult.overflow else {
                appendTruncationStatus(index)
                break
            }
            let entryEnd = entryEndResult.partialValue
            guard entryEnd <= end,
                let sampleNumber = try readUInt32(reader, at: cursor, end: end)
            else {
                appendTruncationStatus(index)
                break
            }
            let byteRange = entryStart..<entryEnd
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].sample_number",
                    value: String(sampleNumber),
                    description: "Sync sample number (1-based)",
                    byteRange: byteRange
                ))
            entries.append(
                ParsedBoxPayload.SyncSampleTableBox.Entry(
                    index: index,
                    sampleNumber: sampleNumber,
                    byteRange: byteRange
                ))
            cursor = entryEnd
            if cursor <= entryStart {
                break
            }
            index += 1
        }

        let detail: ParsedBoxPayload.Detail?
        if UInt32(entries.count) == entryCount {
            detail = .syncSampleTable(
                ParsedBoxPayload.SyncSampleTableBox(
                    version: fullHeader.version,
                    flags: fullHeader.flags,
                    entryCount: entryCount,
                    entries: entries
                ))
        } else {
            detail = nil
        }

        return ParsedBoxPayload(fields: fields, detail: detail)
    }
}
