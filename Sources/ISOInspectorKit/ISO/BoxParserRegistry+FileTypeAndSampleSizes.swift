import Foundation

extension BoxParserRegistry.DefaultParsers {
    @Sendable static func fileType(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
        let payloadRange = header.payloadRange
        guard payloadRange.lowerBound < payloadRange.upperBound else { return nil }
        let payloadLength = payloadRange.upperBound - payloadRange.lowerBound
        guard payloadLength >= 8 else { return nil }

        var fields: [ParsedBoxPayload.Field] = []
        let start = payloadRange.lowerBound
        var compatibleBrands: [FourCharCode] = []

        let major = try? reader.readFourCC(at: start)
        if let major {
            fields.append(ParsedBoxPayload.Field(
                name: "major_brand",
                value: major.rawValue,
                description: "Primary brand identifying the file",
                byteRange: start..<(start + 4)
            ))
        }

        let minorVersion = try readUInt32(reader, at: start + 4, end: payloadRange.upperBound)
        if let minor = minorVersion {
            fields.append(ParsedBoxPayload.Field(
                name: "minor_version",
                value: String(minor),
                description: "File type minor version",
                byteRange: (start + 4)..<(start + 8)
            ))
        }

        var offset = start + 8
        var index = 0
        while offset + 4 <= payloadRange.upperBound {
            guard let brand = try readFourCC(reader, at: offset, end: payloadRange.upperBound) else { break }
            let range = offset..<(offset + 4)
            fields.append(ParsedBoxPayload.Field(
                name: "compatible_brand[\(index)]",
                value: brand.rawValue,
                description: "Brand compatibility entry",
                byteRange: range
            ))
            compatibleBrands.append(brand)
            offset += 4
            index += 1
        }

        guard !fields.isEmpty else { return nil }

        let detail: ParsedBoxPayload.Detail?
        if let major, let minor = minorVersion {
            detail = .fileType(ParsedBoxPayload.FileTypeBox(
                majorBrand: major,
                minorVersion: minor,
                compatibleBrands: compatibleBrands
            ))
        } else {
            detail = nil
        }

        return ParsedBoxPayload(fields: fields, detail: detail)
    }

    @Sendable static func sampleSize(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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

        let defaultEndResult = cursor.addingReportingOverflow(4)
        guard !defaultEndResult.overflow else { return nil }
        let defaultEnd = defaultEndResult.partialValue
        guard defaultEnd <= end,
              let defaultSampleSize = try readUInt32(reader, at: cursor, end: end) else { return nil }
        let defaultRange = cursor..<defaultEnd
        fields.append(ParsedBoxPayload.Field(
            name: "sample_size",
            value: String(defaultSampleSize),
            description: "Default sample size (0 = variable)",
            byteRange: defaultRange
        ))
        cursor = defaultEnd

        let countEndResult = cursor.addingReportingOverflow(4)
        guard !countEndResult.overflow else { return nil }
        let countEnd = countEndResult.partialValue
        guard countEnd <= end,
              let sampleCount = try readUInt32(reader, at: cursor, end: end) else { return nil }
        let countRange = cursor..<countEnd
        fields.append(ParsedBoxPayload.Field(
            name: "sample_count",
            value: String(sampleCount),
            description: "Number of samples in table",
            byteRange: countRange
        ))
        cursor = countEnd

        var entries: [ParsedBoxPayload.SampleSizeBox.Entry] = []

        func appendTruncationStatus(_ entryIndex: UInt32) {
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].status",
                value: "truncated",
                description: "Entry truncated before size field completed",
                byteRange: nil
            ))
        }

        if defaultSampleSize == 0 {
            var index: UInt32 = 0
            while index < sampleCount {
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
                      let entrySize = try readUInt32(reader, at: cursor, end: end) else {
                    appendTruncationStatus(index)
                    break
                }
                let byteRange = entryStart..<entryEnd
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].size",
                    value: String(entrySize),
                    description: "Sample size entry",
                    byteRange: byteRange
                ))
                entries.append(ParsedBoxPayload.SampleSizeBox.Entry(
                    index: index,
                    size: entrySize,
                    byteRange: byteRange
                ))
                cursor = entryEnd
                if cursor <= entryStart {
                    break
                }
                index += 1
            }

            let detail: ParsedBoxPayload.Detail?
            if UInt32(entries.count) == sampleCount {
                detail = .sampleSize(ParsedBoxPayload.SampleSizeBox(
                    version: fullHeader.version,
                    flags: fullHeader.flags,
                    defaultSampleSize: defaultSampleSize,
                    sampleCount: sampleCount,
                    entries: entries
                ))
            } else {
                detail = nil
            }

            return ParsedBoxPayload(fields: fields, detail: detail)
        } else {
            let detail = ParsedBoxPayload.SampleSizeBox(
                version: fullHeader.version,
                flags: fullHeader.flags,
                defaultSampleSize: defaultSampleSize,
                sampleCount: sampleCount,
                entries: []
            )
            return ParsedBoxPayload(fields: fields, detail: .sampleSize(detail))
        }
    }

    @Sendable static func compactSampleSize(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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

        let reservedEndResult = cursor.addingReportingOverflow(3)
        guard !reservedEndResult.overflow else { return nil }
        let reservedEnd = reservedEndResult.partialValue
        guard reservedEnd <= end,
              let reservedData = try readData(reader, at: cursor, count: 3, end: end) else { return nil }
        let reservedValue = reservedData.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let reservedRange = cursor..<reservedEnd
        fields.append(ParsedBoxPayload.Field(
            name: "reserved",
            value: String(format: "0x%06X", reservedValue),
            description: "Reserved value (must be zero)",
            byteRange: reservedRange
        ))
        cursor = reservedEnd

        let fieldSizeEndResult = cursor.addingReportingOverflow(1)
        guard !fieldSizeEndResult.overflow else { return nil }
        let fieldSizeEnd = fieldSizeEndResult.partialValue
        guard fieldSizeEnd <= end else { return nil }
        let fieldSizeData = try reader.read(at: cursor, count: 1)
        guard fieldSizeData.count == 1, let fieldSize = fieldSizeData.first else { return nil }
        let fieldSizeRange = cursor..<fieldSizeEnd
        fields.append(ParsedBoxPayload.Field(
            name: "field_size",
            value: String(fieldSize),
            description: "Bit width of each entry",
            byteRange: fieldSizeRange
        ))
        cursor = fieldSizeEnd

        let countEndResult = cursor.addingReportingOverflow(4)
        guard !countEndResult.overflow else { return nil }
        let countEnd = countEndResult.partialValue
        guard countEnd <= end,
              let sampleCount = try readUInt32(reader, at: cursor, end: end) else { return nil }
        let countRange = cursor..<countEnd
        fields.append(ParsedBoxPayload.Field(
            name: "sample_count",
            value: String(sampleCount),
            description: "Number of samples in table",
            byteRange: countRange
        ))
        cursor = countEnd

        var entries: [ParsedBoxPayload.CompactSampleSizeBox.Entry] = []

        func appendTruncationStatus(_ entryIndex: UInt32) {
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].status",
                value: "truncated",
                description: "Entry truncated before size field completed",
                byteRange: nil
            ))
        }

        if fieldSize > 0, sampleCount > 0 {
            let expectedBits = Int(sampleCount) * Int(fieldSize)
            let expectedBytes = (expectedBits + 7) / 8
            let remainingBytes = Int(max(0, end - cursor))
            let bytesToRead = min(expectedBytes, remainingBytes)
            let data = try reader.read(at: cursor, count: bytesToRead)
            let actualBytes = data.count
            let cursorStart = cursor
            cursor += Int64(actualBytes)

            struct BitCursor {
                let bytes: [UInt8]
                var bitOffset: Int = 0

                mutating func read(bits count: Int) -> (value: UInt32, range: Range<Int>)? {
                    guard count > 0, count <= 32 else { return nil }
                    let start = bitOffset
                    var value: UInt32 = 0
                    for _ in 0..<count {
                        guard bitOffset < bytes.count * 8 else { return nil }
                        let byteIndex = bitOffset / 8
                        let bitIndex = 7 - (bitOffset % 8)
                        let bit = (bytes[byteIndex] >> bitIndex) & 0x01
                        value = (value << 1) | UInt32(bit)
                        bitOffset += 1
                    }
                    return (value, start..<(start + count))
                }
            }

            var cursorReader = BitCursor(bytes: Array(data))
            var index: UInt32 = 0
            var truncated = false

            while index < sampleCount {
                guard let result = cursorReader.read(bits: Int(fieldSize)) else {
                    appendTruncationStatus(index)
                    truncated = true
                    break
                }
                let byteStart = cursorStart + Int64(result.range.lowerBound / 8)
                let byteEnd = cursorStart + Int64((result.range.upperBound + 7) / 8)
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].size",
                    value: String(result.value),
                    description: "Sample size entry",
                    byteRange: byteStart..<byteEnd
                ))
                entries.append(ParsedBoxPayload.CompactSampleSizeBox.Entry(
                    index: index,
                    size: UInt32(result.value),
                    byteRange: byteStart..<byteEnd
                ))
                index += 1
            }

            if truncated || UInt32(entries.count) != sampleCount {
                return ParsedBoxPayload(fields: fields, detail: nil)
            }

            if actualBytes < expectedBytes {
                return ParsedBoxPayload(fields: fields, detail: nil)
            }
        }

        let detail = ParsedBoxPayload.CompactSampleSizeBox(
            version: fullHeader.version,
            flags: fullHeader.flags,
            fieldSize: fieldSize,
            sampleCount: sampleCount,
            entries: entries
        )
        return ParsedBoxPayload(fields: fields, detail: .compactSampleSize(detail))
    }
}
