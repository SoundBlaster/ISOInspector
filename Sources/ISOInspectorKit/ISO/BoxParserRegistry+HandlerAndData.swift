import Foundation

extension BoxParserRegistry.DefaultParsers {
    @Sendable static func handlerReference(header: BoxHeader, reader: RandomAccessReader) throws
        -> ParsedBoxPayload?
    {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else {
            return nil
        }

        var fields: [ParsedBoxPayload.Field] = []
        let start = header.payloadRange.lowerBound
        let end = header.payloadRange.upperBound

        fields.append(
            ParsedBoxPayload.Field(
                name: "version", value: String(fullHeader.version),
                description: "Structure version", byteRange: start..<(start + 1)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "flags", value: String(format: "0x%06X", fullHeader.flags),
                description: "Bit flags", byteRange: (start + 1)..<(start + 4)))

        var cursor = fullHeader.contentStart

        guard let preDefined = try readUInt32(reader, at: cursor, end: end) else { return nil }
        fields.append(
            ParsedBoxPayload.Field(
                name: "pre_defined", value: String(preDefined), description: "Reserved value",
                byteRange: cursor..<(cursor + 4)))
        cursor += 4

        let handlerRange = cursor..<(cursor + 4)
        guard let handlerCode = try readFourCC(reader, at: cursor, end: end) else { return nil }
        fields.append(
            ParsedBoxPayload.Field(
                name: "handler_type", value: handlerCode.rawValue,
                description: "Handler type identifier", byteRange: handlerRange))
        let handler = HandlerType(code: handlerCode)
        if let category = handler.category {
            fields.append(
                ParsedBoxPayload.Field(
                    name: "handler_category", value: category.displayName,
                    description: "Handler role classification"))
        }
        cursor += 4

        let reservedLength: Int64 = 12
        guard cursor + reservedLength <= end else { return ParsedBoxPayload(fields: fields) }
        cursor += reservedLength

        let remainingLength = max(0, fullHeader.contentRange.upperBound - cursor)
        if remainingLength > 0, let remaining = Int(exactly: remainingLength), remaining > 0 {
            let data = try reader.read(at: cursor, count: remaining)
            if let nameField = decodeHandlerName(from: data, at: cursor) {
                fields.append(nameField)
            }
        }

        return ParsedBoxPayload(fields: fields)
    }

    @Sendable static func dataInformation(header: BoxHeader, reader _: RandomAccessReader) throws
        -> ParsedBoxPayload?
    {
        guard header.payloadRange.lowerBound <= header.payloadRange.upperBound else { return nil }
        return ParsedBoxPayload()
    }

    @Sendable static func dataReference(header: BoxHeader, reader: RandomAccessReader) throws
        -> ParsedBoxPayload?
    {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else {
            return nil
        }

        var fields: [ParsedBoxPayload.Field] = []
        let start = header.payloadRange.lowerBound
        let end = header.payloadRange.upperBound

        fields.append(
            ParsedBoxPayload.Field(
                name: "version", value: String(fullHeader.version),
                description: "Structure version", byteRange: start..<(start + 1)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "flags", value: String(format: "0x%06X", fullHeader.flags),
                description: "Bit flags", byteRange: (start + 1)..<(start + 4)))

        var cursor = fullHeader.contentStart

        let countEndResult = cursor.addingReportingOverflow(4)
        guard !countEndResult.overflow else { return nil }
        let countEnd = countEndResult.partialValue
        guard countEnd <= end, let entryCount = try readUInt32(reader, at: cursor, end: end) else {
            return nil
        }
        let countRange = cursor..<countEnd
        fields.append(
            ParsedBoxPayload.Field(
                name: "entry_count", value: String(entryCount),
                description: "Number of data reference entries", byteRange: countRange))
        cursor = countEnd

        var entries: [ParsedBoxPayload.DataReferenceBox.Entry] = []

        func appendTruncationStatus(_ index: UInt32, reason: String) {
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].status", value: "truncated", description: reason,
                    byteRange: nil))
        }

        var index: UInt32 = 0
        while index < entryCount {
            guard cursor < end else {
                appendTruncationStatus(index, reason: "Entry truncated before size field")
                break
            }

            let entryStart = cursor
            guard let declaredSize = try readUInt32(reader, at: cursor, end: end) else {
                appendTruncationStatus(index, reason: "Unable to read entry size")
                break
            }

            var headerLength: Int64 = 8
            var totalSize = Int64(declaredSize)
            if declaredSize == 1 {
                headerLength = 16
                let largeSizeOffset = cursor + 8
                guard largeSizeOffset + 8 <= end,
                    let largeSize = try readUInt64(reader, at: largeSizeOffset, end: end)
                else {
                    appendTruncationStatus(index, reason: "Unable to read extended entry size")
                    break
                }
                totalSize = Int64(largeSize)
            } else if declaredSize == 0 {
                totalSize = end - cursor
            }

            guard totalSize >= headerLength + 4 else {
                appendTruncationStatus(index, reason: "Entry shorter than minimum header")
                break
            }

            let entryEndResult = cursor.addingReportingOverflow(totalSize)
            guard !entryEndResult.overflow else {
                appendTruncationStatus(index, reason: "Entry size overflow")
                break
            }
            let entryEnd = entryEndResult.partialValue
            guard entryEnd <= end else {
                appendTruncationStatus(index, reason: "Entry exceeds box payload")
                break
            }

            let typeRange = (cursor + 4)..<(cursor + 8)
            guard let entryType = try readFourCC(reader, at: cursor + 4, end: end) else {
                appendTruncationStatus(index, reason: "Unable to read entry type")
                break
            }
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].type", value: entryType.rawValue,
                    description: "Data reference entry type", byteRange: typeRange))

            let versionOffset = cursor + headerLength
            guard versionOffset + 4 <= entryEnd else {
                appendTruncationStatus(index, reason: "Entry missing version/flags")
                break
            }
            let versionData = try reader.read(at: versionOffset, count: 1)
            guard versionData.count == 1, let entryVersion = versionData.first else {
                appendTruncationStatus(index, reason: "Unable to read entry version")
                break
            }
            let flagsData = try reader.read(at: versionOffset + 1, count: 3)
            guard flagsData.count == 3 else {
                appendTruncationStatus(index, reason: "Unable to read entry flags")
                break
            }
            let entryFlags = flagsData.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }

            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].version", value: String(entryVersion),
                    description: "Entry version", byteRange: versionOffset..<(versionOffset + 1)))

            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].flags", value: String(format: "0x%06X", entryFlags),
                    description: "Entry flags", byteRange: (versionOffset + 1)..<(versionOffset + 4)
                ))

            let selfContained = (entryFlags & 0x000001) != 0
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(index)].self_contained",
                    value: selfContained ? "true" : "false",
                    description: "Indicates media data is stored in the same file", byteRange: nil))

            let payloadStart = versionOffset + 4
            let payloadLength = max(Int64(0), entryEnd - payloadStart)
            let payloadRange =
                payloadLength > 0 ? payloadStart..<entryEnd : payloadStart..<payloadStart
            if payloadLength > 0 {
                fields.append(
                    ParsedBoxPayload.Field(
                        name: "entries[\(index)].payload_length", value: String(payloadLength),
                        description: "Bytes in location payload", byteRange: payloadRange))
            }

            let payloadData: Data
            if payloadLength == 0 {
                payloadData = Data()
            } else if payloadLength <= Int64(Int.max),
                let data = try readData(
                    reader, at: payloadStart, count: Int(payloadLength), end: entryEnd)
            {
                payloadData = data
            } else {
                appendTruncationStatus(index, reason: "Unable to read entry payload")
                break
            }

            let locationResult = decodeDataReferenceLocation(
                entryIndex: index, type: entryType, payload: payloadData,
                payloadStart: payloadStart, selfContained: selfContained)
            fields.append(contentsOf: locationResult.fields)

            let entryFieldRange = entryStart..<entryEnd
            entries.append(
                ParsedBoxPayload.DataReferenceBox.Entry(
                    index: index, type: entryType, version: entryVersion, flags: entryFlags,
                    location: locationResult.location, byteRange: entryFieldRange,
                    payloadRange: payloadLength > 0 ? payloadRange : nil))

            cursor = entryEnd
            if cursor <= entryStart { break }
            index += 1
        }

        let detail: ParsedBoxPayload.Detail?
        if UInt32(entries.count) == entryCount {
            detail = .dataReference(
                ParsedBoxPayload.DataReferenceBox(
                    version: fullHeader.version, flags: fullHeader.flags, entryCount: entryCount,
                    entries: entries))
        } else {
            detail = nil
        }

        return ParsedBoxPayload(fields: fields, detail: detail)
    }

    private static func decodeDataReferenceLocation(
        entryIndex: UInt32, type: FourCharCode, payload: Data, payloadStart: Int64,
        selfContained: Bool
    ) -> (
        fields: [ParsedBoxPayload.Field], location: ParsedBoxPayload.DataReferenceBox.Entry.Location
    ) {
        var fields: [ParsedBoxPayload.Field] = []

        if payload.isEmpty {
            if selfContained { return (fields, .selfContained) }
            return (fields, .empty)
        }

        switch type.rawValue {
        case "url ":
            let trimmed = trimTrailingNulls(payload)
            if let string = decodeUTF8String(from: trimmed), !string.isEmpty {
                let end = payloadStart + Int64(trimmed.count)
                let range = payloadStart..<end
                fields.append(
                    ParsedBoxPayload.Field(
                        name: "entries[\(entryIndex)].location", value: string,
                        description: "URL location", byteRange: range))
                return (fields, .url(string))
            }
            return (fields, .data(payload))

        case "urn ":
            var name: String?
            var nameRange: Range<Int64>?
            var location: String?
            var locationRange: Range<Int64>?

            var cursor = payloadStart
            var remainder = payload[...]

            if let zeroIndex = remainder.firstIndex(of: 0) {
                let nameSlice = remainder[..<zeroIndex]
                if let decoded = decodeUTF8String(from: Data(nameSlice)), !decoded.isEmpty {
                    let length = nameSlice.count
                    name = decoded
                    nameRange = cursor..<(cursor + Int64(length))
                }
                let step = remainder.distance(from: remainder.startIndex, to: zeroIndex) + 1
                cursor += Int64(step)
                remainder = remainder.suffix(from: remainder.index(after: zeroIndex))
            } else {
                if let decoded = decodeUTF8String(from: Data(remainder)), !decoded.isEmpty {
                    let length = remainder.count
                    name = decoded
                    nameRange = cursor..<(cursor + Int64(length))
                }
                remainder = Data()[...]
            }

            if let locationIndex = remainder.firstIndex(of: 0) {
                let locationSlice = remainder[..<locationIndex]
                if let decoded = decodeUTF8String(from: Data(locationSlice)), !decoded.isEmpty {
                    let length = locationSlice.count
                    location = decoded
                    locationRange = cursor..<(cursor + Int64(length))
                }
            } else if !remainder.isEmpty {
                if let decoded = decodeUTF8String(from: Data(remainder)), !decoded.isEmpty {
                    let length = remainder.count
                    location = decoded
                    locationRange = cursor..<(cursor + Int64(length))
                }
            }

            if let name, let range = nameRange {
                fields.append(
                    ParsedBoxPayload.Field(
                        name: "entries[\(entryIndex)].name", value: name, description: "URN name",
                        byteRange: range))
            }

            if let location, let range = locationRange {
                fields.append(
                    ParsedBoxPayload.Field(
                        name: "entries[\(entryIndex)].location", value: location,
                        description: "URN location", byteRange: range))
            }

            return (fields, .urn(name: name, location: location))

        default: return (fields, .data(payload))
        }
    }

    private static func trimTrailingNulls(_ data: Data) -> Data {
        var trimmed = data
        while let last = trimmed.last, last == 0 { trimmed.removeLast() }
        return trimmed
    }

    private static func decodeUTF8String(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
