import Foundation

public struct BoxParserRegistry: Sendable {
    public typealias Parser = @Sendable (_ header: BoxHeader, _ reader: RandomAccessReader) throws -> ParsedBoxPayload?

    private var typeParsers: [FourCharCode: Parser]
    private var extendedTypeParsers: [UUID: Parser]
    private let fallback: Parser

    public init(
        typeParsers: [FourCharCode: Parser] = [:],
        extendedTypeParsers: [UUID: Parser] = [:],
        fallback: Parser? = nil
    ) {
        self.typeParsers = typeParsers
        self.extendedTypeParsers = extendedTypeParsers
        self.fallback = fallback ?? { _, _ in nil }
    }

    public mutating func register(parser: @escaping Parser, for type: FourCharCode) {
        typeParsers[type] = parser
    }

    public mutating func register(parser: @escaping Parser, forExtendedType uuid: UUID) {
        extendedTypeParsers[uuid] = parser
    }

    public func parser(for header: BoxHeader) -> Parser {
        if let uuid = header.uuid, let parser = extendedTypeParsers[uuid] {
            return parser
        }
        if let parser = typeParsers[header.type] {
            return parser
        }
        return fallback
    }

    public func parse(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
        try parser(for: header)(header, reader)
    }

    public func registering(parser: @escaping Parser, for type: FourCharCode) -> BoxParserRegistry {
        var copy = self
        copy.register(parser: parser, for: type)
        return copy
    }

    public func registering(parser: @escaping Parser, forExtendedType uuid: UUID) -> BoxParserRegistry {
        var copy = self
        copy.register(parser: parser, forExtendedType: uuid)
        return copy
    }
    public static let shared: BoxParserRegistry = {
        var registry = BoxParserRegistry()
        DefaultParsers.registerAll(into: &registry)
        return registry
    }()

    private enum DefaultParsers {
        static func registerAll(into registry: inout BoxParserRegistry) {
            if let ftyp = try? FourCharCode("ftyp") {
                registry.register(parser: fileType, for: ftyp)
            }
            if let mvhd = try? FourCharCode("mvhd") {
                registry.register(parser: movieHeader, for: mvhd)
            }
            if let tkhd = try? FourCharCode("tkhd") {
                registry.register(parser: trackHeader, for: tkhd)
            }
            if let mdhd = try? FourCharCode("mdhd") {
                registry.register(parser: mediaHeader, for: mdhd)
            }
        }

        static func fileType(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
            let payloadRange = header.payloadRange
            guard payloadRange.lowerBound < payloadRange.upperBound else { return nil }
            let payloadLength = payloadRange.upperBound - payloadRange.lowerBound
            guard payloadLength >= 8 else { return nil }

            var fields: [ParsedBoxPayload.Field] = []
            let start = payloadRange.lowerBound
            let major = try? reader.readFourCC(at: start)
            if let major {
                fields.append(ParsedBoxPayload.Field(
                    name: "major_brand",
                    value: major.rawValue,
                    description: "Primary brand identifying the file",
                    byteRange: start..<(start + 4)
                ))
            }

            if let minor = try readUInt32(reader, at: start + 4, end: payloadRange.upperBound) {
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
                offset += 4
                index += 1
            }

            return fields.isEmpty ? nil : ParsedBoxPayload(fields: fields)
        }

        static func mediaHeader(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
            guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else { return nil }

            let start = header.payloadRange.lowerBound
            let end = header.payloadRange.upperBound
            let availableContent = fullHeader.contentRange.upperBound - fullHeader.contentRange.lowerBound
            let minimumContentLength: Int64 = fullHeader.version == 1 ? 8 + 8 + 4 + 8 + 2 + 2 : 4 + 4 + 4 + 4 + 2 + 2
            guard availableContent >= minimumContentLength else { return nil }

            var fields: [ParsedBoxPayload.Field] = []
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

            if fullHeader.version == 1 {
                guard let creation = try readUInt64(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "creation_time",
                    value: String(creation),
                    description: "Media creation timestamp",
                    byteRange: cursor..<(cursor + 8)
                ))
                cursor += 8

                guard let modification = try readUInt64(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "modification_time",
                    value: String(modification),
                    description: "Last modification timestamp",
                    byteRange: cursor..<(cursor + 8)
                ))
                cursor += 8

                guard let timescale = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "timescale",
                    value: String(timescale),
                    description: "Media time units per second",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4

                guard let duration = try readUInt64(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "duration",
                    value: String(duration),
                    description: "Media duration",
                    byteRange: cursor..<(cursor + 8)
                ))
                cursor += 8
            } else {
                guard let creation = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "creation_time",
                    value: String(creation),
                    description: "Media creation timestamp",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4

                guard let modification = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "modification_time",
                    value: String(modification),
                    description: "Last modification timestamp",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4

                guard let timescale = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "timescale",
                    value: String(timescale),
                    description: "Media time units per second",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4

                guard let duration = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "duration",
                    value: String(duration),
                    description: "Media duration",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4
            }

            guard let languageRaw = try readUInt16(reader, at: cursor, end: end) else { return nil }
            let languageValue = decodeISO639Language(languageRaw) ?? String(format: "0x%04X", languageRaw)
            fields.append(ParsedBoxPayload.Field(
                name: "language",
                value: languageValue,
                description: "ISO-639-2/T language code",
                byteRange: cursor..<(cursor + 2)
            ))
            cursor += 2

            guard let preDefined = try readUInt16(reader, at: cursor, end: end) else { return nil }
            fields.append(ParsedBoxPayload.Field(
                name: "pre_defined",
                value: String(preDefined),
                description: "Reserved value",
                byteRange: cursor..<(cursor + 2)
            ))

            return ParsedBoxPayload(fields: fields)
        }

        static func movieHeader(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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
            if fullHeader.version == 1 {
                if let creation = try readUInt64(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "creation_time",
                        value: String(creation),
                        description: "Movie creation timestamp",
                        byteRange: cursor..<(cursor + 8)
                    ))
                    cursor += 8
                }
                if let modification = try readUInt64(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "modification_time",
                        value: String(modification),
                        description: "Last modification timestamp",
                        byteRange: cursor..<(cursor + 8)
                    ))
                    cursor += 8
                }
                if let timescale = try readUInt32(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "timescale",
                        value: String(timescale),
                        description: "Time units per second",
                        byteRange: cursor..<(cursor + 4)
                    ))
                    cursor += 4
                }
                if let duration = try readUInt64(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "duration",
                        value: String(duration),
                        description: "Movie duration",
                        byteRange: cursor..<(cursor + 8)
                    ))
                    cursor += 8
                }
            } else {
                if let creation = try readUInt32(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "creation_time",
                        value: String(creation),
                        description: "Movie creation timestamp",
                        byteRange: cursor..<(cursor + 4)
                    ))
                    cursor += 4
                }
                if let modification = try readUInt32(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "modification_time",
                        value: String(modification),
                        description: "Last modification timestamp",
                        byteRange: cursor..<(cursor + 4)
                    ))
                    cursor += 4
                }
                if let timescale = try readUInt32(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "timescale",
                        value: String(timescale),
                        description: "Time units per second",
                        byteRange: cursor..<(cursor + 4)
                    ))
                    cursor += 4
                }
                if let duration = try readUInt32(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "duration",
                        value: String(duration),
                        description: "Movie duration",
                        byteRange: cursor..<(cursor + 4)
                    ))
                    cursor += 4
                }
            }

            if let rate = try readUInt32(reader, at: cursor, end: end) {
                fields.append(ParsedBoxPayload.Field(
                    name: "rate",
                    value: formatFixedPoint(rate, integerBits: 16),
                    description: "Playback rate",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4
            }

            if let volumeData = try readData(reader, at: cursor, count: 2, end: end) {
                let raw = UInt16(volumeData[0]) << 8 | UInt16(volumeData[1])
                let value = Double(raw) / 256.0
                fields.append(ParsedBoxPayload.Field(
                    name: "volume",
                    value: String(format: "%.2f", value),
                    description: "Playback volume",
                    byteRange: cursor..<(cursor + 2)
                ))
                cursor += 2
            }

            cursor += 2 // reserved
            cursor += 8 // reserved 32-bit fields
            cursor += 36 // matrix
            cursor += 24 // predefined

            if let nextTrack = try readUInt32(reader, at: cursor, end: end) {
                fields.append(ParsedBoxPayload.Field(
                    name: "next_track_ID",
                    value: String(nextTrack),
                    description: "Next track identifier",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4
            }

            return fields.isEmpty ? nil : ParsedBoxPayload(fields: fields)
        }

        static func trackHeader(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
            guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else { return nil }

            let start = header.payloadRange.lowerBound
            let end = header.payloadRange.upperBound

            var fields: [ParsedBoxPayload.Field] = []
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
            if fullHeader.version == 1 {
                if let creation = try readUInt64(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "creation_time",
                        value: String(creation),
                        description: "Track creation timestamp",
                        byteRange: cursor..<(cursor + 8)
                    ))
                    cursor += 8
                }
                if let modification = try readUInt64(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "modification_time",
                        value: String(modification),
                        description: "Last modification timestamp",
                        byteRange: cursor..<(cursor + 8)
                    ))
                    cursor += 8
                }
            } else {
                if let creation = try readUInt32(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "creation_time",
                        value: String(creation),
                        description: "Track creation timestamp",
                        byteRange: cursor..<(cursor + 4)
                    ))
                    cursor += 4
                }
                if let modification = try readUInt32(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "modification_time",
                        value: String(modification),
                        description: "Last modification timestamp",
                        byteRange: cursor..<(cursor + 4)
                    ))
                    cursor += 4
                }
            }

            if let trackID = try readUInt32(reader, at: cursor, end: end) {
                fields.append(ParsedBoxPayload.Field(
                    name: "track_id",
                    value: String(trackID),
                    description: "Unique track identifier",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4
            }

            cursor += 4 // reserved

            if fullHeader.version == 1 {
                if let duration = try readUInt64(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "duration",
                        value: String(duration),
                        description: "Track duration",
                        byteRange: cursor..<(cursor + 8)
                    ))
                    cursor += 8
                }
            } else {
                if let duration = try readUInt32(reader, at: cursor, end: end) {
                    fields.append(ParsedBoxPayload.Field(
                        name: "duration",
                        value: String(duration),
                        description: "Track duration",
                        byteRange: cursor..<(cursor + 4)
                    ))
                    cursor += 4
                }
            }

            cursor += 8 // reserved

            if let layer = try readInt16(reader, at: cursor, end: end) {
                fields.append(ParsedBoxPayload.Field(
                    name: "layer",
                    value: String(layer),
                    description: "Track layer",
                    byteRange: cursor..<(cursor + 2)
                ))
                cursor += 2
            }

            if let alternateGroup = try readInt16(reader, at: cursor, end: end) {
                fields.append(ParsedBoxPayload.Field(
                    name: "alternate_group",
                    value: String(alternateGroup),
                    description: "Alternate group",
                    byteRange: cursor..<(cursor + 2)
                ))
                cursor += 2
            }

            if let volumeData = try readData(reader, at: cursor, count: 2, end: end) {
                let raw = UInt16(volumeData[0]) << 8 | UInt16(volumeData[1])
                let value = Double(raw) / 256.0
                fields.append(ParsedBoxPayload.Field(
                    name: "volume",
                    value: String(format: "%.2f", value),
                    description: "Playback volume",
                    byteRange: cursor..<(cursor + 2)
                ))
            }
            cursor += 2
            cursor += 2 // reserved

            cursor += 36 // matrix
            cursor += 24 // predefined

            if let nextTrack = try readUInt32(reader, at: cursor, end: end) {
                fields.append(ParsedBoxPayload.Field(
                    name: "next_track_ID",
                    value: String(nextTrack),
                    description: "Next track identifier",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4
            }

            if let width = try readUInt32(reader, at: cursor, end: end) {
                fields.append(ParsedBoxPayload.Field(
                    name: "width",
                    value: formatFixedPoint(width, integerBits: 16),
                    description: "Track width",
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4
            }

            if let height = try readUInt32(reader, at: cursor, end: end) {
                fields.append(ParsedBoxPayload.Field(
                    name: "height",
                    value: formatFixedPoint(height, integerBits: 16),
                    description: "Track height",
                    byteRange: cursor..<(cursor + 4)
                ))
            }

            return fields.isEmpty ? nil : ParsedBoxPayload(fields: fields)
        }

        private static func readData(
            _ reader: RandomAccessReader,
            at offset: Int64,
            count: Int,
            end: Int64
        ) throws -> Data? {
            guard offset + Int64(count) <= end else { return nil }
            let data = try reader.read(at: offset, count: count)
            guard data.count == count else { return nil }
            return data
        }

        private static func readUInt16(
            _ reader: RandomAccessReader,
            at offset: Int64,
            end: Int64
        ) throws -> UInt16? {
            guard offset + 2 <= end else { return nil }
            guard let data = try? reader.read(at: offset, count: 2), data.count == 2 else { return nil }
            return (UInt16(data[0]) << 8) | UInt16(data[1])
        }

        private static func decodeISO639Language(_ rawValue: UInt16) -> String? {
            if rawValue == 0x7FFF {
                return "und"
            }
            let first = UInt8((rawValue >> 10) & 0x1F)
            let second = UInt8((rawValue >> 5) & 0x1F)
            let third = UInt8(rawValue & 0x1F)
            guard first != 0, second != 0, third != 0 else { return nil }
            let bytes = [first + 0x60, second + 0x60, third + 0x60]
            return String(bytes: bytes, encoding: .ascii)
        }

        private static func readUInt32(
            _ reader: RandomAccessReader,
            at offset: Int64,
            end: Int64
        ) throws -> UInt32? {
            guard offset + 4 <= end else { return nil }
            return try? reader.readUInt32(at: offset)
        }

        private static func readUInt64(
            _ reader: RandomAccessReader,
            at offset: Int64,
            end: Int64
        ) throws -> UInt64? {
            guard offset + 8 <= end else { return nil }
            return try? reader.readUInt64(at: offset)
        }

        private static func readFourCC(
            _ reader: RandomAccessReader,
            at offset: Int64,
            end: Int64
        ) throws -> FourCharCode? {
            guard offset + 4 <= end else { return nil }
            return try? reader.readFourCC(at: offset)
        }

        private static func readInt16(
            _ reader: RandomAccessReader,
            at offset: Int64,
            end: Int64
        ) throws -> Int16? {
            guard offset + 2 <= end else { return nil }
            guard let data = try? reader.read(at: offset, count: 2), data.count == 2 else { return nil }
            let value = Int16(bitPattern: UInt16(data[0]) << 8 | UInt16(data[1]))
            return value
        }

        private static func formatFixedPoint(_ value: UInt32, integerBits: Int) -> String {
            let fractionalBits = 32 - integerBits
            let scale = Double(1 << fractionalBits)
            let integer = Int32(bitPattern: value) >> fractionalBits
            let fractional = Double(value & UInt32((1 << fractionalBits) - 1)) / scale
            return String(format: "%.2f", Double(integer) + fractional)
        }
    }
}
