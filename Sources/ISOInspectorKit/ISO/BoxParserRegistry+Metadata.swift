import Foundation

extension BoxParserRegistry.DefaultParsers {
    static func userData(header: BoxHeader, reader _: RandomAccessReader) throws -> ParsedBoxPayload? {
        guard header.payloadRange.lowerBound <= header.payloadRange.upperBound else { return nil }
        return ParsedBoxPayload()
    }

    static func metadata(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else { return nil }

        var fields: [ParsedBoxPayload.Field] = []
        let payloadStart = header.payloadRange.lowerBound
        let payloadEnd = header.payloadRange.upperBound

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

        let reservedStart = fullHeader.contentStart
        guard reservedStart + 4 <= payloadEnd,
              let reserved = try readUInt32(reader, at: reservedStart, end: payloadEnd) else { return nil }
        let reservedRange = reservedStart..<(reservedStart + 4)
        fields.append(ParsedBoxPayload.Field(
            name: "reserved",
            value: String(format: "0x%08X", reserved),
            description: "Reserved value",
            byteRange: reservedRange
        ))

        let detail = ParsedBoxPayload.Detail.metadata(
            ParsedBoxPayload.MetadataBox(
                version: fullHeader.version,
                flags: fullHeader.flags,
                reserved: reserved
            )
        )

        return ParsedBoxPayload(fields: fields, detail: detail)
    }

    static func metadataKeys(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
        guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else { return nil }

        var fields: [ParsedBoxPayload.Field] = []
        let payloadStart = header.payloadRange.lowerBound
        let payloadEnd = header.payloadRange.upperBound

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
        guard cursor + 4 <= payloadEnd,
              let entryCountRaw = try readUInt32(reader, at: cursor, end: payloadEnd),
              let entryCount = Int(exactly: entryCountRaw) else { return nil }
        let countRange = cursor..<(cursor + 4)
        fields.append(ParsedBoxPayload.Field(
            name: "entry_count",
            value: String(entryCountRaw),
            description: "Number of metadata key entries",
            byteRange: countRange
        ))
        cursor += 4

        var entries: [ParsedBoxPayload.MetadataKeyTableBox.Entry] = []
        entries.reserveCapacity(entryCount)

        for index in 0..<entryCount {
            guard cursor + 4 <= payloadEnd,
                  let keySize = try readUInt32(reader, at: cursor, end: payloadEnd) else { break }
            let sizeRange = cursor..<(cursor + 4)
            cursor += 4

            let entrySize = Int64(keySize)
            guard entrySize >= 4 else {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].status",
                    value: "invalid",
                    description: "Entry shorter than namespace field",
                    byteRange: nil
                ))
                break
            }

            let entryEnd = cursor + entrySize
            guard entryEnd <= payloadEnd else {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].status",
                    value: "truncated",
                    description: "Entry exceeds available payload",
                    byteRange: nil
                ))
                break
            }

            guard let namespaceData = try readData(reader, at: cursor, count: 4, end: payloadEnd) else { break }
            let namespaceRange = cursor..<(cursor + 4)
            cursor += 4
            let nameLength = Int(entrySize) - 4
            guard nameLength >= 0,
                  let nameData = try readData(reader, at: cursor, count: nameLength, end: payloadEnd) else { break }
            let nameRange = cursor..<(cursor + Int64(nameLength))
            cursor += Int64(nameLength)

            let namespace = String(data: namespaceData, encoding: .ascii) ?? bytesToHex(namespaceData)
            let name = String(data: nameData, encoding: .utf8) ?? bytesToHex(nameData)

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].size",
                value: String(keySize),
                description: "Entry size",
                byteRange: sizeRange
            ))
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].namespace",
                value: namespace,
                description: "Metadata key namespace",
                byteRange: namespaceRange
            ))
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].name",
                value: name,
                description: "Metadata key name",
                byteRange: nameRange
            ))

            entries.append(ParsedBoxPayload.MetadataKeyTableBox.Entry(
                index: UInt32(index + 1),
                namespace: namespace,
                name: name
            ))
        }

        let detail = ParsedBoxPayload.Detail.metadataKeyTable(
            ParsedBoxPayload.MetadataKeyTableBox(
                version: fullHeader.version,
                flags: fullHeader.flags,
                entries: entries
            )
        )

        return ParsedBoxPayload(fields: fields, detail: detail)
    }

    static func metadataItemList(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
        let payloadStart = header.payloadRange.lowerBound
        let payloadEnd = header.payloadRange.upperBound
        guard payloadStart <= payloadEnd else { return nil }

        var fields: [ParsedBoxPayload.Field] = []
        let environment = BoxParserRegistry.resolveMetadataEnvironment(header: header, reader: reader)

        if let handler = environment.handlerType {
            fields.append(ParsedBoxPayload.Field(
                name: "handler_type",
                value: handler.rawValue,
                description: "Owning metadata handler"
            ))
            if let category = handler.category?.displayName {
                fields.append(ParsedBoxPayload.Field(
                    name: "handler_category",
                    value: category,
                    description: "Handler category"
                ))
            }
        }

        var cursor = payloadStart
        var entries: [ParsedBoxPayload.MetadataItemListBox.Entry] = []
        var entryIndex = 0

        while cursor + 8 <= payloadEnd {
            guard let entrySize = try readUInt32(reader, at: cursor, end: payloadEnd) else { break }
            let typeOffset = cursor + 4
            let entryEnd = cursor + Int64(entrySize)
            guard entrySize >= 8, entryEnd <= payloadEnd else { break }
            guard let identifierData = try readData(reader, at: typeOffset, count: 4, end: payloadEnd) else { break }

            let rawIdentifier = identifierData.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            let identifierRange = typeOffset..<(typeOffset + 4)

            let identifier: ParsedBoxPayload.MetadataItemListBox.Entry.Identifier
            var namespace: String?
            var name: String?

            if let keyEntry = environment.keyTable[rawIdentifier] {
                identifier = .keyIndex(rawIdentifier)
                namespace = keyEntry.namespace
                name = keyEntry.name
            } else if let decoded = decodeMetadataIdentifier(rawIdentifier) {
                identifier = .fourCC(raw: rawIdentifier, display: decoded)
                namespace = environment.handlerType?.rawValue
                name = decoded
            } else {
                identifier = .raw(rawIdentifier)
                namespace = environment.handlerType?.rawValue
            }

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].identifier",
                value: displayIdentifier(identifier),
                description: "Metadata entry identifier",
                byteRange: identifierRange
            ))

            if let namespace {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].namespace",
                    value: namespace,
                    description: "Entry namespace"
                ))
            }

            if let name {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].name",
                    value: name,
                    description: "Entry name"
                ))
            }

            var valueCursor = cursor + 8
            var values: [ParsedBoxPayload.MetadataItemListBox.Entry.Value] = []
            var valueIndex = 0

            while valueCursor + 8 <= entryEnd {
                guard let childSize = try readUInt32(reader, at: valueCursor, end: entryEnd), childSize >= 8 else { break }
                let childEnd = valueCursor + Int64(childSize)
                guard childEnd <= entryEnd,
                      let childType = try readFourCC(reader, at: valueCursor + 4, end: entryEnd) else { break }
                let contentStart = valueCursor + 8

                if childType.rawValue == "data" {
                    guard contentStart + 4 <= childEnd else { break }
                    let version = try reader.read(at: contentStart, count: 1)
                    guard version.count == 1 else { break }
                    let flagBytes = try reader.read(at: contentStart + 1, count: 3)
                    guard flagBytes.count == 3 else { break }
                    let rawType = flagBytes.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
                    guard let locale = try readUInt32(reader, at: contentStart + 4, end: childEnd) else { break }
                    let dataStart = contentStart + 8
                    guard dataStart <= childEnd else { break }
                    let dataLength = Int(childEnd - dataStart)
                    let data = try reader.read(at: dataStart, count: dataLength)

                    let kindAndValue = decodeMetadataValue(type: rawType, data: data)
                    let valueKind = kindAndValue.kind
                    let valueString = kindAndValue.display

                    fields.append(ParsedBoxPayload.Field(
                        name: "entries[\(entryIndex)].values[\(valueIndex)].type",
                        value: kindAndValue.typeDescription,
                        description: "Value type"
                    ))
                    fields.append(ParsedBoxPayload.Field(
                        name: "entries[\(entryIndex)].values[\(valueIndex)].raw_type",
                        value: String(format: "0x%06X", rawType),
                        description: "Raw data type"
                    ))
                    fields.append(ParsedBoxPayload.Field(
                        name: "entries[\(entryIndex)].values[\(valueIndex)].value",
                        value: valueString,
                        description: "Decoded value",
                        byteRange: dataStart..<(dataStart + Int64(dataLength))
                    ))

                    if locale != 0 {
                        fields.append(ParsedBoxPayload.Field(
                            name: "entries[\(entryIndex)].values[\(valueIndex)].locale",
                            value: String(format: "0x%08X", locale),
                            description: "Locale or reserved value"
                        ))
                    }

                    values.append(ParsedBoxPayload.MetadataItemListBox.Entry.Value(
                        kind: valueKind,
                        rawType: rawType,
                        locale: locale
                    ))
                    valueIndex += 1
                }

                valueCursor = childEnd
            }

            entries.append(ParsedBoxPayload.MetadataItemListBox.Entry(
                identifier: identifier,
                namespace: namespace,
                name: name,
                values: values
            ))

            cursor = entryEnd
            entryIndex += 1
        }

        fields.append(ParsedBoxPayload.Field(
            name: "entry_count",
            value: String(entries.count),
            description: "Number of metadata entries"
        ))

        let detail = ParsedBoxPayload.Detail.metadataItemList(
            ParsedBoxPayload.MetadataItemListBox(
                handlerType: environment.handlerType,
                entries: entries
            )
        )

        return ParsedBoxPayload(fields: fields, detail: detail)
    }
}

private extension BoxParserRegistry.DefaultParsers {
    static func decodeMetadataIdentifier(_ raw: UInt32) -> String? {
        var bigEndian = raw.bigEndian
        let data = withUnsafeBytes(of: &bigEndian, { Data($0) })
        if let ascii = String(data: data, encoding: .ascii),
           ascii.unicodeScalars.allSatisfy({ $0.value >= 0x20 && $0.value <= 0x7E }) {
            return ascii
        }
        if let latin1 = String(data: data, encoding: .isoLatin1),
           latin1.unicodeScalars.allSatisfy({ $0.value >= 0x20 }) {
            return latin1
        }
        return String(data: data, encoding: .macOSRoman)
    }

    static func displayIdentifier(
        _ identifier: ParsedBoxPayload.MetadataItemListBox.Entry.Identifier
    ) -> String {
        switch identifier {
        case .fourCC(let raw, let display):
            if display.isEmpty {
                return String(format: "0x%08X", raw)
            }
            return display
        case .keyIndex(let index):
            return "key[\(index)]"
        case .raw(let value):
            return String(format: "0x%08X", value)
        }
    }

    private struct MetadataValueDescription {
        let kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind
        let display: String
        let typeDescription: String
    }

    private static func decodeMetadataValue(type: UInt32, data: Data) -> MetadataValueDescription {
        switch type {
        case 1:
            if let string = String(data: data, encoding: .utf8) {
                return MetadataValueDescription(kind: .utf8(string), display: string, typeDescription: "UTF-8")
            }
        case 2:
            if let string = String(data: data, encoding: .utf16BigEndian) {
                return MetadataValueDescription(kind: .utf16(string), display: string, typeDescription: "UTF-16")
            }
        case 21:
            if let value = parseSignedInteger(from: data) {
                return MetadataValueDescription(kind: .integer(value), display: String(value), typeDescription: "Integer")
            }
        case 22:
            if let value = parseUnsignedInteger(from: data) {
                return MetadataValueDescription(
                    kind: .unsignedInteger(value),
                    display: String(value),
                    typeDescription: "Unsigned Integer"
                )
            }
        default:
            break
        }

        let hex = bytesToHex(data)
        return MetadataValueDescription(
            kind: .bytes(data),
            display: hex,
            typeDescription: String(format: "type=0x%06X", type)
        )
    }

    static func bytesToHex(_ data: Data) -> String {
        if data.isEmpty { return "" }
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    static func parseSignedInteger(from data: Data) -> Int64? {
        guard !data.isEmpty, data.count <= MemoryLayout<Int64>.size else { return nil }
        var value: Int64 = 0
        for byte in data {
            value = (value << 8) | Int64(UInt8(byte))
        }
        let totalBits = data.count * 8
        if totalBits < 64 {
            let shift = 64 - totalBits
            value = (value << shift) >> shift
        }
        return value
    }

    static func parseUnsignedInteger(from data: Data) -> UInt64? {
        guard !data.isEmpty, data.count <= MemoryLayout<UInt64>.size else { return nil }
        var value: UInt64 = 0
        for byte in data {
            value = (value << 8) | UInt64(byte)
        }
        return value
    }
}
