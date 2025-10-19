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
            if let hdlr = try? FourCharCode("hdlr") {
                registry.register(parser: handlerReference, for: hdlr)
            }
            if let stsd = try? FourCharCode("stsd") {
                registry.register(parser: sampleDescription, for: stsd)
            }
            if let stsc = try? FourCharCode("stsc") {
                registry.register(parser: sampleToChunk, for: stsc)
            }
        }

        private static let visualSampleEntryTypes: Set<FourCharCode> = {
            let rawValues = [
                "avc1", "avc2", "avc3", "avc4",
                "hvc1", "hev1", "dvh1", "dvhe",
                "encv"
            ]
            let codes = rawValues.compactMap { try? FourCharCode($0) }
            return Set(codes)
        }()

        private static let audioSampleEntryTypes: Set<FourCharCode> = {
            let rawValues = ["mp4a", "enca"]
            let codes = rawValues.compactMap { try? FourCharCode($0) }
            return Set(codes)
        }()

        private static let avcSampleEntryTypes: Set<FourCharCode> = {
            let rawValues = ["avc1", "avc2", "avc3", "avc4"]
            let codes = rawValues.compactMap { try? FourCharCode($0) }
            return Set(codes)
        }()

        private static let hevcSampleEntryTypes: Set<FourCharCode> = {
            let rawValues = ["hvc1", "hev1", "dvh1", "dvhe"]
            let codes = rawValues.compactMap { try? FourCharCode($0) }
            return Set(codes)
        }()

        private static let protectedSampleEntryTypes: Set<FourCharCode> = {
            let rawValues = ["encv", "enca"]
            let codes = rawValues.compactMap { try? FourCharCode($0) }
            return Set(codes)
        }()

        static func fileType(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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

            let availableContent = fullHeader.contentRange.upperBound - fullHeader.contentRange.lowerBound
            let minimumContentLength: Int64 = fullHeader.version == 1 ? 108 : 92
            guard availableContent >= minimumContentLength else { return nil }

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
            let creationTime: UInt64
            let modificationTime: UInt64
            let timescale: UInt32
            let duration: UInt64
            let durationIs64Bit: Bool

            if fullHeader.version == 1 {
                guard let creation = try readUInt64(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "creation_time",
                    value: String(creation),
                    description: "Movie creation timestamp",
                    byteRange: cursor..<(cursor + 8)
                ))
                creationTime = creation
                cursor += 8

                guard let modification = try readUInt64(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "modification_time",
                    value: String(modification),
                    description: "Last modification timestamp",
                    byteRange: cursor..<(cursor + 8)
                ))
                modificationTime = modification
                cursor += 8

                guard let parsedTimescale = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "timescale",
                    value: String(parsedTimescale),
                    description: "Time units per second",
                    byteRange: cursor..<(cursor + 4)
                ))
                timescale = parsedTimescale
                cursor += 4

                guard let durationValue = try readUInt64(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "duration",
                    value: String(durationValue),
                    description: "Movie duration",
                    byteRange: cursor..<(cursor + 8)
                ))
                duration = durationValue
                durationIs64Bit = true
                cursor += 8
            } else {
                guard let creation = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "creation_time",
                    value: String(creation),
                    description: "Movie creation timestamp",
                    byteRange: cursor..<(cursor + 4)
                ))
                creationTime = UInt64(creation)
                cursor += 4

                guard let modification = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "modification_time",
                    value: String(modification),
                    description: "Last modification timestamp",
                    byteRange: cursor..<(cursor + 4)
                ))
                modificationTime = UInt64(modification)
                cursor += 4

                guard let parsedTimescale = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "timescale",
                    value: String(parsedTimescale),
                    description: "Time units per second",
                    byteRange: cursor..<(cursor + 4)
                ))
                timescale = parsedTimescale
                cursor += 4

                guard let durationValue = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "duration",
                    value: String(durationValue),
                    description: "Movie duration",
                    byteRange: cursor..<(cursor + 4)
                ))
                duration = UInt64(durationValue)
                durationIs64Bit = false
                cursor += 4
            }

            guard let rateRaw = try readUInt32(reader, at: cursor, end: end) else { return nil }
            let rateValue = decodeSignedFixedPoint(Int32(bitPattern: rateRaw), fractionalBits: 16)
            fields.append(ParsedBoxPayload.Field(
                name: "rate",
                value: String(format: "%.2f", rateValue),
                description: "Playback rate",
                byteRange: cursor..<(cursor + 4)
            ))
            cursor += 4

            guard let volumeData = try readData(reader, at: cursor, count: 2, end: end) else { return nil }
            let rawVolume = UInt16(volumeData[0]) << 8 | UInt16(volumeData[1])
            let volumeValue = Double(rawVolume) / 256.0
            fields.append(ParsedBoxPayload.Field(
                name: "volume",
                value: String(format: "%.2f", volumeValue),
                description: "Playback volume",
                byteRange: cursor..<(cursor + 2)
            ))
            cursor += 2

            guard cursor + 10 <= end else { return nil }
            cursor += 10 // reserved bytes

            struct MatrixEntry {
                let name: String
                let description: String
                let fractionalBits: Int
                let precision: Int
            }

            let matrixEntries: [MatrixEntry] = [
                MatrixEntry(name: "matrix.a", description: "Matrix element a (row 1 column 1)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.b", description: "Matrix element b (row 1 column 2)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.u", description: "Matrix element u (row 1 column 3)", fractionalBits: 30, precision: 6),
                MatrixEntry(name: "matrix.c", description: "Matrix element c (row 2 column 1)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.d", description: "Matrix element d (row 2 column 2)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.v", description: "Matrix element v (row 2 column 3)", fractionalBits: 30, precision: 6),
                MatrixEntry(name: "matrix.x", description: "Matrix element x (row 3 column 1)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.y", description: "Matrix element y (row 3 column 2)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.w", description: "Matrix element w (row 3 column 3)", fractionalBits: 30, precision: 6)
            ]

            var matrixValues: [Double] = []
            for entry in matrixEntries {
                guard let raw = try readUInt32(reader, at: cursor, end: end) else { return nil }
                let signed = Int32(bitPattern: raw)
                let decoded = decodeSignedFixedPoint(signed, fractionalBits: entry.fractionalBits)
                matrixValues.append(decoded)
                fields.append(ParsedBoxPayload.Field(
                    name: entry.name,
                    value: formatSignedFixedPoint(signed, fractionalBits: entry.fractionalBits, precision: entry.precision),
                    description: entry.description,
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4
            }

            guard cursor + 24 <= end else { return nil }
            cursor += 24 // predefined reserved fields

            guard let nextTrack = try readUInt32(reader, at: cursor, end: end) else { return nil }
            fields.append(ParsedBoxPayload.Field(
                name: "next_track_ID",
                value: String(nextTrack),
                description: "Next track identifier",
                byteRange: cursor..<(cursor + 4)
            ))
            cursor += 4

            guard matrixValues.count == 9 else { return nil }
            let matrix = ParsedBoxPayload.TransformationMatrix(
                a: matrixValues[0],
                b: matrixValues[1],
                u: matrixValues[2],
                c: matrixValues[3],
                d: matrixValues[4],
                v: matrixValues[5],
                x: matrixValues[6],
                y: matrixValues[7],
                w: matrixValues[8]
            )

            let detail = ParsedBoxPayload.MovieHeaderBox(
                version: fullHeader.version,
                creationTime: creationTime,
                modificationTime: modificationTime,
                timescale: timescale,
                duration: duration,
                durationIs64Bit: durationIs64Bit,
                rate: rateValue,
                volume: volumeValue,
                matrix: matrix,
                nextTrackID: nextTrack
            )

            return ParsedBoxPayload(fields: fields, detail: .movieHeader(detail))
        }

        static func trackHeader(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
            guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else { return nil }

            let start = header.payloadRange.lowerBound
            let end = header.payloadRange.upperBound
            let availableContent = fullHeader.contentRange.upperBound - fullHeader.contentRange.lowerBound
            let minimumContentLength: Int64 = fullHeader.version == 1 ? 92 : 80
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
            let creationTime: UInt64
            let modificationTime: UInt64
            let trackID: UInt32
            let duration: UInt64
            let durationIs64Bit: Bool

            if fullHeader.version == 1 {
                guard let creation = try readUInt64(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "creation_time",
                    value: String(creation),
                    description: "Track creation timestamp",
                    byteRange: cursor..<(cursor + 8)
                ))
                creationTime = creation
                cursor += 8

                guard let modification = try readUInt64(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "modification_time",
                    value: String(modification),
                    description: "Last modification timestamp",
                    byteRange: cursor..<(cursor + 8)
                ))
                modificationTime = modification
                cursor += 8
            } else {
                guard let creation = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "creation_time",
                    value: String(creation),
                    description: "Track creation timestamp",
                    byteRange: cursor..<(cursor + 4)
                ))
                creationTime = UInt64(creation)
                cursor += 4

                guard let modification = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "modification_time",
                    value: String(modification),
                    description: "Last modification timestamp",
                    byteRange: cursor..<(cursor + 4)
                ))
                modificationTime = UInt64(modification)
                cursor += 4
            }

            guard let parsedTrackID = try readUInt32(reader, at: cursor, end: end) else { return nil }
            fields.append(ParsedBoxPayload.Field(
                name: "track_id",
                value: String(parsedTrackID),
                description: "Unique track identifier",
                byteRange: cursor..<(cursor + 4)
            ))
            trackID = parsedTrackID
            cursor += 4

            cursor += 4 // reserved

            if fullHeader.version == 1 {
                guard let durationValue = try readUInt64(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "duration",
                    value: String(durationValue),
                    description: "Track duration",
                    byteRange: cursor..<(cursor + 8)
                ))
                duration = durationValue
                durationIs64Bit = true
                cursor += 8
            } else {
                guard let durationValue = try readUInt32(reader, at: cursor, end: end) else { return nil }
                fields.append(ParsedBoxPayload.Field(
                    name: "duration",
                    value: String(durationValue),
                    description: "Track duration",
                    byteRange: cursor..<(cursor + 4)
                ))
                duration = UInt64(durationValue)
                durationIs64Bit = false
                cursor += 4
            }

            cursor += 8 // reserved

            guard let layerValue = try readInt16(reader, at: cursor, end: end) else { return nil }
            fields.append(ParsedBoxPayload.Field(
                name: "layer",
                value: String(layerValue),
                description: "Track layer",
                byteRange: cursor..<(cursor + 2)
            ))
            cursor += 2

            guard let alternateGroupValue = try readInt16(reader, at: cursor, end: end) else { return nil }
            fields.append(ParsedBoxPayload.Field(
                name: "alternate_group",
                value: String(alternateGroupValue),
                description: "Alternate group",
                byteRange: cursor..<(cursor + 2)
            ))
            cursor += 2

            guard let volumeData = try readData(reader, at: cursor, count: 2, end: end) else { return nil }
            let rawVolume = UInt16(volumeData[0]) << 8 | UInt16(volumeData[1])
            let volumeValue = Double(rawVolume) / 256.0
            fields.append(ParsedBoxPayload.Field(
                name: "volume",
                value: String(format: "%.2f", volumeValue),
                description: "Playback volume",
                byteRange: cursor..<(cursor + 2)
            ))
            cursor += 2

            guard cursor + 2 <= end else { return nil }
            cursor += 2 // reserved

            struct MatrixEntry {
                let name: String
                let description: String
                let fractionalBits: Int
                let precision: Int
            }

            let matrixEntries: [MatrixEntry] = [
                MatrixEntry(name: "matrix.a", description: "Matrix element a (row 1 column 1)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.b", description: "Matrix element b (row 1 column 2)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.u", description: "Matrix element u (row 1 column 3)", fractionalBits: 30, precision: 6),
                MatrixEntry(name: "matrix.c", description: "Matrix element c (row 2 column 1)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.d", description: "Matrix element d (row 2 column 2)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.v", description: "Matrix element v (row 2 column 3)", fractionalBits: 30, precision: 6),
                MatrixEntry(name: "matrix.x", description: "Matrix element x (row 3 column 1)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.y", description: "Matrix element y (row 3 column 2)", fractionalBits: 16, precision: 4),
                MatrixEntry(name: "matrix.w", description: "Matrix element w (row 3 column 3)", fractionalBits: 30, precision: 6)
            ]

            var matrixValues: [Double] = []
            for entry in matrixEntries {
                guard let raw = try readUInt32(reader, at: cursor, end: end) else { return nil }
                let signed = Int32(bitPattern: raw)
                let decoded = decodeSignedFixedPoint(signed, fractionalBits: entry.fractionalBits)
                matrixValues.append(decoded)
                fields.append(ParsedBoxPayload.Field(
                    name: entry.name,
                    value: formatSignedFixedPoint(signed, fractionalBits: entry.fractionalBits, precision: entry.precision),
                    description: entry.description,
                    byteRange: cursor..<(cursor + 4)
                ))
                cursor += 4
            }

            guard matrixValues.count == 9 else { return nil }

            guard let widthRaw = try readUInt32(reader, at: cursor, end: end) else { return nil }
            let widthValue = Double(widthRaw) / 65536.0
            fields.append(ParsedBoxPayload.Field(
                name: "width",
                value: formatFixedPoint(widthRaw, integerBits: 16),
                description: "Track width",
                byteRange: cursor..<(cursor + 4)
            ))
            cursor += 4

            guard let heightRaw = try readUInt32(reader, at: cursor, end: end) else { return nil }
            let heightValue = Double(heightRaw) / 65536.0
            fields.append(ParsedBoxPayload.Field(
                name: "height",
                value: formatFixedPoint(heightRaw, integerBits: 16),
                description: "Track height",
                byteRange: cursor..<(cursor + 4)
            ))

            let isEnabled = (fullHeader.flags & 0x000001) != 0
            let isInMovie = (fullHeader.flags & 0x000002) != 0
            let isInPreview = (fullHeader.flags & 0x000004) != 0
            fields.append(ParsedBoxPayload.Field(
                name: "is_enabled",
                value: isEnabled ? "true" : "false",
                description: "Track enabled flag",
                byteRange: nil
            ))
            fields.append(ParsedBoxPayload.Field(
                name: "is_in_movie",
                value: isInMovie ? "true" : "false",
                description: "Track participates in movie presentation",
                byteRange: nil
            ))
            fields.append(ParsedBoxPayload.Field(
                name: "is_in_preview",
                value: isInPreview ? "true" : "false",
                description: "Track participates in preview presentation",
                byteRange: nil
            ))

            let matrix = ParsedBoxPayload.TransformationMatrix(
                a: matrixValues[0],
                b: matrixValues[1],
                u: matrixValues[2],
                c: matrixValues[3],
                d: matrixValues[4],
                v: matrixValues[5],
                x: matrixValues[6],
                y: matrixValues[7],
                w: matrixValues[8]
            )

            let detail = ParsedBoxPayload.TrackHeaderBox(
                version: fullHeader.version,
                flags: fullHeader.flags,
                creationTime: creationTime,
                modificationTime: modificationTime,
                trackID: trackID,
                duration: duration,
                durationIs64Bit: durationIs64Bit,
                layer: layerValue,
                alternateGroup: alternateGroupValue,
                volume: volumeValue,
                matrix: matrix,
                width: widthValue,
                height: heightValue,
                isEnabled: isEnabled,
                isInMovie: isInMovie,
                isInPreview: isInPreview
            )

            return ParsedBoxPayload(fields: fields, detail: .trackHeader(detail))
        }

        static func sampleDescription(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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
            guard let entryCount = try readUInt32(reader, at: cursor, end: end) else { return nil }
            fields.append(ParsedBoxPayload.Field(
                name: "entry_count",
                value: String(entryCount),
                description: "Number of sample entries",
                byteRange: cursor..<(cursor + 4)
            ))
            cursor += 4

            var index: UInt32 = 0
            while index < entryCount, cursor < end {
                guard let result = try parseSampleEntry(
                    reader: reader,
                    startOffset: cursor,
                    end: end,
                    index: Int(index)
                ) else {
                    break
                }
                fields.append(contentsOf: result.fields)
                cursor = result.nextOffset
                if cursor <= result.startOffset {
                    break
                }
                index += 1
            }

            return ParsedBoxPayload(fields: fields)
        }

        static func sampleToChunk(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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
            let entryCountOffset = cursor
            let entryCountEndResult = cursor.addingReportingOverflow(4)
            guard !entryCountEndResult.overflow else { return nil }
            let entryCountEnd = entryCountEndResult.partialValue
            guard let entryCount = try readUInt32(reader, at: cursor, end: end) else { return nil }
            fields.append(ParsedBoxPayload.Field(
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
                fields.append(ParsedBoxPayload.Field(
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
                guard firstChunkEnd <= end, let firstChunk = try readUInt32(reader, at: cursor, end: end) else {
                    appendTruncationStatus("first_chunk")
                    break
                }
                let firstChunkRange = cursor..<firstChunkEnd
                fields.append(ParsedBoxPayload.Field(
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
                      let samplesPerChunk = try readUInt32(reader, at: cursor, end: end) else {
                    appendTruncationStatus("samples_per_chunk")
                    break
                }
                let samplesRange = cursor..<samplesPerChunkEnd
                fields.append(ParsedBoxPayload.Field(
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
                      let sampleDescriptionIndex = try readUInt32(reader, at: cursor, end: end) else {
                    appendTruncationStatus("sample_description_index")
                    break
                }
                let descriptionRange = cursor..<descriptionIndexEnd
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].sample_description_index",
                    value: String(sampleDescriptionIndex),
                    description: "Index into the sample description table",
                    byteRange: descriptionRange
                ))
                cursor = descriptionIndexEnd

                let entryRange = entryStart..<cursor
                entries.append(ParsedBoxPayload.SampleToChunkBox.Entry(
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
                detail = .sampleToChunk(ParsedBoxPayload.SampleToChunkBox(
                    version: fullHeader.version,
                    flags: fullHeader.flags,
                    entries: entries
                ))
            } else {
                detail = nil
            }

            return ParsedBoxPayload(fields: fields, detail: detail)
        }

        static func handlerReference(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
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

            guard let preDefined = try readUInt32(reader, at: cursor, end: end) else { return nil }
            fields.append(ParsedBoxPayload.Field(
                name: "pre_defined",
                value: String(preDefined),
                description: "Reserved value",
                byteRange: cursor..<(cursor + 4)
            ))
            cursor += 4

            let handlerRange = cursor..<(cursor + 4)
            guard let handlerCode = try readFourCC(reader, at: cursor, end: end) else { return nil }
            fields.append(ParsedBoxPayload.Field(
                name: "handler_type",
                value: handlerCode.rawValue,
                description: "Handler type identifier",
                byteRange: handlerRange
            ))
            let handler = HandlerType(code: handlerCode)
            if let category = handler.category {
                fields.append(ParsedBoxPayload.Field(
                    name: "handler_category",
                    value: category.displayName,
                    description: "Handler role classification"
                ))
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

        private struct SampleEntryParseResult {
            let fields: [ParsedBoxPayload.Field]
            let nextOffset: Int64
            let startOffset: Int64
        }

        private static func parseSampleEntry(
            reader: RandomAccessReader,
            startOffset: Int64,
            end: Int64,
            index: Int
        ) throws -> SampleEntryParseResult? {
            guard startOffset + 8 <= end else { return nil }
            guard let declaredSize = try readUInt32(reader, at: startOffset, end: end) else { return nil }
            guard let format = try readFourCC(reader, at: startOffset + 4, end: end) else { return nil }

            let resolvedLength: Int64
            if declaredSize == 0 {
                resolvedLength = end - startOffset
            } else {
                resolvedLength = Int64(declaredSize)
            }
            guard resolvedLength > 0 else { return nil }
            let endOffsetResult = startOffset.addingReportingOverflow(resolvedLength)
            guard endOffsetResult.overflow == false else { return nil }
            let entryEnd = endOffsetResult.partialValue
            guard entryEnd <= end else { return nil }
            guard resolvedLength >= 16 else { return nil }

            var fields: [ParsedBoxPayload.Field] = []
            let recordedLength = declaredSize == 0 ? resolvedLength : Int64(declaredSize)
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].byte_length",
                value: String(recordedLength),
                description: "Sample entry byte length",
                byteRange: startOffset..<(startOffset + 4)
            ))

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].format",
                value: format.rawValue,
                description: "Sample entry format",
                byteRange: (startOffset + 4)..<(startOffset + 8)
            ))

            let baseStart = startOffset + 8
            let dataReferenceOffset = baseStart + 6
            guard dataReferenceOffset + 2 <= entryEnd else { return nil }
            guard let dataReferenceIndex = try readUInt16(reader, at: dataReferenceOffset, end: entryEnd) else {
                return nil
            }
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(index)].data_reference_index",
                value: String(dataReferenceIndex),
                description: "Data reference index",
                byteRange: dataReferenceOffset..<(dataReferenceOffset + 2)
            ))

            let contentStart = dataReferenceOffset + 2

            let baseHeaderLength = sampleEntryHeaderLength(for: format)

            if visualSampleEntryTypes.contains(format) {
                fields.append(contentsOf: parseVisualSampleEntry(
                    reader: reader,
                    contentStart: contentStart,
                    entryEnd: entryEnd,
                    index: index
                ))
            } else if audioSampleEntryTypes.contains(format) {
                fields.append(contentsOf: parseAudioSampleEntry(
                    reader: reader,
                    contentStart: contentStart,
                    entryEnd: entryEnd,
                    index: index
                ))
            }

            guard let headerLength = baseHeaderLength else {
                return SampleEntryParseResult(fields: fields, nextOffset: entryEnd, startOffset: startOffset)
            }

            let childBoxes = parseChildBoxes(
                reader: reader,
                contentStart: contentStart,
                entryEnd: entryEnd,
                baseHeaderLength: headerLength
            )

            var effectiveFormat = format
            if protectedSampleEntryTypes.contains(format) {
                let protection = parseProtectedSampleEntry(
                    reader: reader,
                    boxes: childBoxes,
                    entryIndex: index
                )
                effectiveFormat = protection.originalFormat ?? format
                fields.append(contentsOf: protection.fields)
            }

            fields.append(contentsOf: parseCodecSpecificFields(
                format: effectiveFormat,
                boxes: childBoxes,
                reader: reader,
                entryIndex: index
            ))

            return SampleEntryParseResult(fields: fields, nextOffset: entryEnd, startOffset: startOffset)
        }

        private static func parseVisualSampleEntry(
            reader: RandomAccessReader,
            contentStart: Int64,
            entryEnd: Int64,
            index: Int
        ) -> [ParsedBoxPayload.Field] {
            var fields: [ParsedBoxPayload.Field] = []
            let widthOffset = contentStart + 16
            let heightOffset = widthOffset + 2

            if widthOffset + 2 <= entryEnd,
               let width = (try? readUInt16(reader, at: widthOffset, end: entryEnd)) ?? nil {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].width",
                    value: String(width),
                    description: "Visual sample width",
                    byteRange: widthOffset..<(widthOffset + 2)
                ))
            }

            if heightOffset + 2 <= entryEnd,
               let height = (try? readUInt16(reader, at: heightOffset, end: entryEnd)) ?? nil {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].height",
                    value: String(height),
                    description: "Visual sample height",
                    byteRange: heightOffset..<(heightOffset + 2)
                ))
            }

            return fields
        }

        private static func parseAudioSampleEntry(
            reader: RandomAccessReader,
            contentStart: Int64,
            entryEnd: Int64,
            index: Int
        ) -> [ParsedBoxPayload.Field] {
            var fields: [ParsedBoxPayload.Field] = []
            let channelCountOffset = contentStart + 8
            let sampleSizeOffset = channelCountOffset + 2
            let sampleRateOffset = contentStart + 16

            if channelCountOffset + 2 <= entryEnd,
               let channelCount = (try? readUInt16(reader, at: channelCountOffset, end: entryEnd)) ?? nil {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].channelcount",
                    value: String(channelCount),
                    description: "Audio channel count",
                    byteRange: channelCountOffset..<(channelCountOffset + 2)
                ))
            }

            if sampleSizeOffset + 2 <= entryEnd,
               let sampleSize = (try? readUInt16(reader, at: sampleSizeOffset, end: entryEnd)) ?? nil {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].samplesize",
                    value: String(sampleSize),
                    description: "Audio sample size",
                    byteRange: sampleSizeOffset..<(sampleSizeOffset + 2)
                ))
            }

            if sampleRateOffset + 4 <= entryEnd,
               let rawRate = try? reader.readUInt32(at: sampleRateOffset) {
                let integerRate = rawRate >> 16
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(index)].samplerate",
                    value: String(integerRate),
                    description: "Audio sample rate",
                    byteRange: sampleRateOffset..<(sampleRateOffset + 4)
                ))
            }

            return fields
        }

        private struct NestedBox {
            let type: FourCharCode
            let range: Range<Int64>
            let payloadRange: Range<Int64>
        }

        private static func sampleEntryHeaderLength(for format: FourCharCode) -> Int64? {
            if visualSampleEntryTypes.contains(format) {
                return 70
            }
            if audioSampleEntryTypes.contains(format) {
                return 20
            }
            return nil
        }

        private static func parseChildBoxes(
            reader: RandomAccessReader,
            contentStart: Int64,
            entryEnd: Int64,
            baseHeaderLength: Int64
        ) -> [NestedBox] {
            var boxes: [NestedBox] = []
            var cursor = contentStart + baseHeaderLength
            guard cursor <= entryEnd else { return boxes }

            while cursor + 8 <= entryEnd {
                guard let size = (try? readUInt32(reader, at: cursor, end: entryEnd)) ?? nil else { break }
                guard let type = (try? readFourCC(reader, at: cursor + 4, end: entryEnd)) ?? nil else { break }

                var headerLength: Int64 = 8
                var boxLength = Int64(size)
                if size == 1 {
                    headerLength = 16
                    guard let largeSize = (try? readUInt64(reader, at: cursor + 8, end: entryEnd)) ?? nil else { break }
                    boxLength = Int64(largeSize)
                } else if size == 0 {
                    boxLength = entryEnd - cursor
                }

                guard boxLength >= headerLength else { break }
                let nextCursor = cursor + boxLength
                guard nextCursor <= entryEnd else { break }

                let payloadStart = cursor + headerLength
                let payloadRange = payloadStart..<nextCursor
                let range = cursor..<nextCursor
                boxes.append(NestedBox(type: type, range: range, payloadRange: payloadRange))

                if nextCursor <= cursor { break }
                cursor = nextCursor
            }

            return boxes
        }

        private static func parseCodecSpecificFields(
            format: FourCharCode,
            boxes: [NestedBox],
            reader: RandomAccessReader,
            entryIndex: Int
        ) -> [ParsedBoxPayload.Field] {
            var fields: [ParsedBoxPayload.Field] = []

            if avcSampleEntryTypes.contains(format),
               let avcBox = boxes.first(where: { $0.type.rawValue == "avcC" }) {
                fields.append(contentsOf: parseAvcConfiguration(
                    reader: reader,
                    box: avcBox,
                    entryIndex: entryIndex
                ))
            }

            if hevcSampleEntryTypes.contains(format),
               let hevcBox = boxes.first(where: { $0.type.rawValue == "hvcC" }) {
                fields.append(contentsOf: parseHevcConfiguration(
                    reader: reader,
                    box: hevcBox,
                    entryIndex: entryIndex
                ))
            }

            if format.rawValue == "mp4a",
               let esdsBox = boxes.first(where: { $0.type.rawValue == "esds" }) {
                fields.append(contentsOf: parseEsdsConfiguration(
                    reader: reader,
                    box: esdsBox,
                    entryIndex: entryIndex
                ))
            }

            return fields
        }

        private static func parseProtectedSampleEntry(
            reader: RandomAccessReader,
            boxes: [NestedBox],
            entryIndex: Int
        ) -> (fields: [ParsedBoxPayload.Field], originalFormat: FourCharCode?) {
            guard let sinfBox = boxes.first(where: { $0.type.rawValue == "sinf" }) else {
                return ([], nil)
            }

            let sinfChildren = parseChildBoxes(
                reader: reader,
                contentStart: sinfBox.payloadRange.lowerBound,
                entryEnd: sinfBox.payloadRange.upperBound,
                baseHeaderLength: 0
            )

            var fields: [ParsedBoxPayload.Field] = []
            var originalFormat: FourCharCode?

            if let frma = sinfChildren.first(where: { $0.type.rawValue == "frma" }),
               let format = try? reader.readFourCC(at: frma.payloadRange.lowerBound) {
                originalFormat = format
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].encryption.original_format",
                    value: format.rawValue,
                    description: "Original codec format before protection",
                    byteRange: frma.payloadRange
                ))
            }

            if let schm = sinfChildren.first(where: { $0.type.rawValue == "schm" }) {
                fields.append(contentsOf: parseSchemeInformation(
                    reader: reader,
                    box: schm,
                    entryIndex: entryIndex
                ))
            }

            if let schi = sinfChildren.first(where: { $0.type.rawValue == "schi" }) {
                let schiChildren = parseChildBoxes(
                    reader: reader,
                    contentStart: schi.payloadRange.lowerBound,
                    entryEnd: schi.payloadRange.upperBound,
                    baseHeaderLength: 0
                )

                if let tenc = schiChildren.first(where: { $0.type.rawValue == "tenc" }) {
                    fields.append(contentsOf: parseTrackEncryption(
                        reader: reader,
                        box: tenc,
                        entryIndex: entryIndex
                    ))
                }
            }

            return (fields, originalFormat)
        }

        private static func parseSchemeInformation(
            reader: RandomAccessReader,
            box: NestedBox,
            entryIndex: Int
        ) -> [ParsedBoxPayload.Field] {
            let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
            guard length > 0,
                  let payload = try? readData(
                      reader,
                      at: box.payloadRange.lowerBound,
                      count: length,
                      end: box.payloadRange.upperBound
                  ) else { return [] }

            guard payload.count >= 8 else { return [] }

            var fields: [ParsedBoxPayload.Field] = []
            guard payload.count >= 8 else { return fields }

            let schemeTypeData = payload[4..<8]
            if let schemeType = String(bytes: schemeTypeData, encoding: .ascii) {
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].encryption.scheme_type",
                    value: schemeType,
                    description: "Protection scheme identifier",
                    byteRange: (box.payloadRange.lowerBound + 4)..<(box.payloadRange.lowerBound + 8)
                ))
            }

            if payload.count >= 12 {
                let schemeVersion = payload[8..<12].reduce(0) { ($0 << 8) | UInt32($1) }
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].encryption.scheme_version",
                    value: String(format: "0x%08X", schemeVersion),
                    description: "Protection scheme version",
                    byteRange: (box.payloadRange.lowerBound + 8)..<(box.payloadRange.lowerBound + 12)
                ))
            }

            if payload.count > 12 {
                let uriData = payload[12..<payload.count]
                if let uri = String(bytes: uriData, encoding: .utf8), !uri.isEmpty {
                    fields.append(ParsedBoxPayload.Field(
                        name: "entries[\(entryIndex)].encryption.scheme_uri",
                        value: uri,
                        description: "Protection scheme URI",
                        byteRange: (box.payloadRange.lowerBound + 12)..<box.payloadRange.upperBound
                    ))
                }
            }

            return fields
        }

        private static func parseTrackEncryption(
            reader: RandomAccessReader,
            box: NestedBox,
            entryIndex: Int
        ) -> [ParsedBoxPayload.Field] {
            let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
            guard length > 0,
                  let payload = try? readData(
                      reader,
                      at: box.payloadRange.lowerBound,
                      count: length,
                      end: box.payloadRange.upperBound
                  ) else { return [] }

            guard payload.count >= 6 else { return [] }

            let defaultIsProtected = payload[4]
            let defaultPerSampleIVSize = payload[5]

            var fields: [ParsedBoxPayload.Field] = []
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].encryption.is_protected",
                value: defaultIsProtected != 0 ? "true" : "false",
                description: "Indicates whether samples are encrypted",
                byteRange: (box.payloadRange.lowerBound + 4)..<(box.payloadRange.lowerBound + 5)
            ))

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].encryption.per_sample_iv_size",
                value: String(defaultPerSampleIVSize),
                description: "Size of per-sample IV in bytes (0 for constant)",
                byteRange: (box.payloadRange.lowerBound + 5)..<(box.payloadRange.lowerBound + 6)
            ))

            if payload.count >= 22 {
                let kidRange = (box.payloadRange.lowerBound + 6)..<(box.payloadRange.lowerBound + 22)
                let kid = payload[6..<22].map { String(format: "%02x", $0) }.joined()
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].encryption.default_kid",
                    value: kid,
                    description: "Default key identifier",
                    byteRange: kidRange
                ))
            }

            if payload.count > 22 {
                let constantIVSize = Int(payload[22])
                let constantIVEnd = 23 + constantIVSize
                if constantIVEnd <= payload.count {
                    let ivData = payload[23..<constantIVEnd].map { String(format: "%02x", $0) }.joined()
                    fields.append(ParsedBoxPayload.Field(
                        name: "entries[\(entryIndex)].encryption.constant_iv",
                        value: ivData,
                        description: "Constant IV for samples when per-sample IV size is zero",
                        byteRange: (box.payloadRange.lowerBound + 23)..<(box.payloadRange.lowerBound + Int64(constantIVEnd))
                    ))
                }
            }

            return fields
        }

        private static func parseAvcConfiguration(
            reader: RandomAccessReader,
            box: NestedBox,
            entryIndex: Int
        ) -> [ParsedBoxPayload.Field] {
            let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
            guard length > 0,
                  let payload = try? readData(
                      reader,
                      at: box.payloadRange.lowerBound,
                      count: length,
                      end: box.payloadRange.upperBound
                  ) else { return [] }

            guard payload.count >= 6 else { return [] }

            var fields: [ParsedBoxPayload.Field] = []
            let baseOffset = box.payloadRange.lowerBound

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.avc.configuration_version",
                value: String(payload[0]),
                description: "AVC configuration version",
                byteRange: baseOffset..<(baseOffset + 1)
            ))

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.avc.profile_indication",
                value: String(format: "0x%02X", payload[1]),
                description: "AVC profile indication",
                byteRange: (baseOffset + 1)..<(baseOffset + 2)
            ))

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.avc.profile_compatibility",
                value: String(format: "0x%02X", payload[2]),
                description: "Profile compatibility flags",
                byteRange: (baseOffset + 2)..<(baseOffset + 3)
            ))

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.avc.level_indication",
                value: String(payload[3]),
                description: "AVC level indication",
                byteRange: (baseOffset + 3)..<(baseOffset + 4)
            ))

            let lengthSizeMinusOne = payload[4] & 0x03
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.avc.nal_unit_length_bytes",
                value: String(Int(lengthSizeMinusOne) + 1),
                description: "Number of bytes used to encode NAL unit length",
                byteRange: (baseOffset + 4)..<(baseOffset + 5)
            ))

            let spsCount = Int(payload[5] & 0x1F)
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.avc.sequence_parameter_sets.count",
                value: String(spsCount),
                description: "Number of SPS entries",
                byteRange: (baseOffset + 5)..<(baseOffset + 6)
            ))

            var offset = 6
            for index in 0..<spsCount {
                guard offset + 2 <= payload.count else { break }
                let length = Int(payload[offset]) << 8 | Int(payload[offset + 1])
                let lengthRange = (baseOffset + Int64(offset))..<(baseOffset + Int64(offset + 2))
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].codec.avc.sequence_parameter_sets[\(index)].length",
                    value: String(length),
                    description: "Sequence parameter set length",
                    byteRange: lengthRange
                ))
                offset += 2 + length
                if offset > payload.count { break }
            }

            guard offset < payload.count else { return fields }
            let ppsCount = Int(payload[offset])
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.avc.picture_parameter_sets.count",
                value: String(ppsCount),
                description: "Number of PPS entries",
                byteRange: (baseOffset + Int64(offset))..<(baseOffset + Int64(offset + 1))
            ))
            offset += 1

            for index in 0..<ppsCount {
                guard offset + 2 <= payload.count else { break }
                let length = Int(payload[offset]) << 8 | Int(payload[offset + 1])
                let lengthRange = (baseOffset + Int64(offset))..<(baseOffset + Int64(offset + 2))
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].codec.avc.picture_parameter_sets[\(index)].length",
                    value: String(length),
                    description: "Picture parameter set length",
                    byteRange: lengthRange
                ))
                offset += 2 + length
                if offset > payload.count { break }
            }

            return fields
        }

        private static func parseHevcConfiguration(
            reader: RandomAccessReader,
            box: NestedBox,
            entryIndex: Int
        ) -> [ParsedBoxPayload.Field] {
            let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
            guard length > 0,
                  let payload = try? readData(
                      reader,
                      at: box.payloadRange.lowerBound,
                      count: length,
                      end: box.payloadRange.upperBound
                  ) else { return [] }

            guard payload.count >= 23 else { return [] }

            var fields: [ParsedBoxPayload.Field] = []
            let baseOffset = box.payloadRange.lowerBound

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.configuration_version",
                value: String(payload[0]),
                description: "HEVC configuration version",
                byteRange: baseOffset..<(baseOffset + 1)
            ))

            let profileSpace = (payload[1] >> 6) & 0x03
            let tierFlag = (payload[1] >> 5) & 0x01
            let profileIDC = payload[1] & 0x1F

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.profile_space",
                value: String(profileSpace),
                description: "Profile space",
                byteRange: (baseOffset + 1)..<(baseOffset + 2)
            ))

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.tier_flag",
                value: tierFlag == 0 ? "main" : "high",
                description: "Tier flag",
                byteRange: (baseOffset + 1)..<(baseOffset + 2)
            ))

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.profile_idc",
                value: String(profileIDC),
                description: "Profile IDC",
                byteRange: (baseOffset + 1)..<(baseOffset + 2)
            ))

            let compatibility = payload[2..<6].reduce(0) { ($0 << 8) | UInt32($1) }
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.profile_compatibility_flags",
                value: String(format: "0x%08X", compatibility),
                description: "Profile compatibility flags",
                byteRange: (baseOffset + 2)..<(baseOffset + 6)
            ))

            let constraintBytes = payload[6..<12]
            let constraintHex = constraintBytes.map { String(format: "%02X", $0) }.joined()
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.constraint_indicator_flags",
                value: "0x\(constraintHex)",
                description: "Constraint indicator flags",
                byteRange: (baseOffset + 6)..<(baseOffset + 12)
            ))

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.level_idc",
                value: String(payload[12]),
                description: "Level IDC",
                byteRange: (baseOffset + 12)..<(baseOffset + 13)
            ))

            let lengthSizeMinusOne = payload[21] & 0x03
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.nal_unit_length_bytes",
                value: String(Int(lengthSizeMinusOne) + 1),
                description: "NAL unit length field size",
                byteRange: (baseOffset + 21)..<(baseOffset + 22)
            ))

            let numArrays = Int(payload[22])
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.nal_arrays",
                value: String(numArrays),
                description: "Number of NAL unit arrays",
                byteRange: (baseOffset + 22)..<(baseOffset + 23)
            ))

            var offset = 23
            var counters: [UInt8: (count: Int, lengths: [Int])] = [:]

            for _ in 0..<numArrays {
                guard offset + 3 <= payload.count else { break }
                let arrayCompleteness = (payload[offset] & 0x80) != 0
                let nalType = payload[offset] & 0x3F
                let numNalus = Int(payload[offset + 1]) << 8 | Int(payload[offset + 2])
                offset += 3

                for _ in 0..<numNalus {
                    guard offset + 2 <= payload.count else { break }
                    let length = Int(payload[offset]) << 8 | Int(payload[offset + 1])
                    offset += 2
                    guard offset + length <= payload.count else { break }
                    counters[nalType, default: (0, [])].count += 1
                    counters[nalType]?.lengths.append(length)
                    offset += length
                }

                if arrayCompleteness {
                    // array completeness doesn't change metadata but ensures we consume all NALUs
                }
            }

            for (nalType, info) in counters {
                let name: String
                switch nalType {
                case 32: name = "vps"
                case 33: name = "sps"
                case 34: name = "pps"
                default: name = "nal_type_\(nalType)"
                }
                fields.append(ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].codec.hevc.\(name).count",
                    value: String(info.count),
                    description: "Number of NAL units of type \(name.uppercased())",
                    byteRange: nil
                ))
                for (index, length) in info.lengths.enumerated() {
                    fields.append(ParsedBoxPayload.Field(
                        name: "entries[\(entryIndex)].codec.hevc.\(name)[\(index)].length",
                        value: String(length),
                        description: "NAL unit length",
                        byteRange: nil
                    ))
                }
            }

            return fields
        }

        private static func parseEsdsConfiguration(
            reader: RandomAccessReader,
            box: NestedBox,
            entryIndex: Int
        ) -> [ParsedBoxPayload.Field] {
            let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
            guard length > 0,
                  let payload = try? readData(
                      reader,
                      at: box.payloadRange.lowerBound,
                      count: length,
                      end: box.payloadRange.upperBound
                  ) else { return [] }

            guard payload.count >= 4 else { return [] }

            let baseOffset = box.payloadRange.lowerBound
            var offset = 4
            var fields: [ParsedBoxPayload.Field] = []

            while offset < payload.count {
                guard let descriptor = readDescriptorHeader(from: payload, at: offset) else { break }
                let bodyStart = offset + descriptor.headerLength
                let bodyEnd = bodyStart + descriptor.length
                guard bodyEnd <= payload.count else { break }

                if descriptor.tag == 0x03 {
                    fields.append(contentsOf: parseESDescriptor(
                        payload: payload,
                        start: bodyStart,
                        length: descriptor.length,
                        baseOffset: baseOffset + Int64(bodyStart),
                        entryIndex: entryIndex
                    ))
                }

                offset = bodyEnd
            }

            return fields
        }

        private struct DescriptorHeader {
            let tag: UInt8
            let length: Int
            let headerLength: Int
        }

        private static func readDescriptorHeader(from data: Data, at offset: Int) -> DescriptorHeader? {
            guard offset < data.count else { return nil }
            let tag = data[offset]
            var length = 0
            var headerLength = 1
            var index = offset + 1
            var iterations = 0

            while index < data.count {
                let byte = data[index]
                length = (length << 7) | Int(byte & 0x7F)
                headerLength += 1
                index += 1
                iterations += 1
                if byte & 0x80 == 0 { break }
                if iterations >= 4 { return nil }
            }

            return DescriptorHeader(tag: tag, length: length, headerLength: headerLength)
        }

        private static func parseESDescriptor(
            payload: Data,
            start: Int,
            length: Int,
            baseOffset: Int64,
            entryIndex: Int
        ) -> [ParsedBoxPayload.Field] {
            guard start + length <= payload.count else { return [] }

            var offset = start
            guard offset + 2 <= start + length else { return [] }
            offset += 2 // ES_ID
            guard offset < start + length else { return [] }
            let flags = payload[offset]
            offset += 1

            if flags & 0x80 != 0 { offset += 2 }
            if flags & 0x40 != 0, offset < start + length {
                let urlLength = Int(payload[offset])
                offset += 1 + urlLength
            }
            if flags & 0x20 != 0 { offset += 2 }

            while offset < start + length {
                guard let descriptor = readDescriptorHeader(from: payload, at: offset) else { break }
                let bodyStart = offset + descriptor.headerLength
                let bodyEnd = bodyStart + descriptor.length
                guard bodyEnd <= start + length else { break }

                if descriptor.tag == 0x04 {
                    return parseDecoderConfigDescriptor(
                        payload: payload,
                        start: bodyStart,
                        length: descriptor.length,
                        baseOffset: baseOffset + Int64(bodyStart),
                        entryIndex: entryIndex
                    )
                }

                offset = bodyEnd
            }

            return []
        }

        private static func parseDecoderConfigDescriptor(
            payload: Data,
            start: Int,
            length: Int,
            baseOffset: Int64,
            entryIndex: Int
        ) -> [ParsedBoxPayload.Field] {
            guard start + length <= payload.count, length >= 13 else { return [] }

            var fields: [ParsedBoxPayload.Field] = []

            let objectType = payload[start]
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.aac.object_type_indication",
                value: String(format: "0x%02X", objectType),
                description: "Object type indication",
                byteRange: baseOffset..<(baseOffset + 1)
            ))

            var offset = start + 13

            while offset < start + length {
                guard let descriptor = readDescriptorHeader(from: payload, at: offset) else { break }
                let bodyStart = offset + descriptor.headerLength
                let bodyEnd = bodyStart + descriptor.length
                guard bodyEnd <= start + length else { break }

                if descriptor.tag == 0x05 {
                    fields.append(contentsOf: parseAudioSpecificConfig(
                        payload: payload,
                        start: bodyStart,
                        length: descriptor.length,
                        baseOffset: baseOffset + Int64(bodyStart),
                        entryIndex: entryIndex
                    ))
                    break
                }

                offset = bodyEnd
            }

            return fields
        }

        private static func parseAudioSpecificConfig(
            payload: Data,
            start: Int,
            length: Int,
            baseOffset: Int64,
            entryIndex: Int
        ) -> [ParsedBoxPayload.Field] {
            guard length >= 2, start + length <= payload.count else { return [] }

            let data = payload[start..<(start + length)]
            var reader = Bitstream(data: Array(data))

            guard let rawObjectType = reader.read(bits: 5),
                  let samplingIndex = reader.read(bits: 4),
                  let channelConfig = reader.read(bits: 4) else { return [] }

            let audioObjectType: Int
            if rawObjectType == 31, let extensionType = reader.read(bits: 6) {
                audioObjectType = 32 + extensionType
            } else {
                audioObjectType = rawObjectType
            }

            var fields: [ParsedBoxPayload.Field] = []
            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.aac.audio_object_type",
                value: String(audioObjectType),
                description: "AAC audio object type",
                byteRange: nil
            ))

            let frequencies = [
                96000, 88200, 64000, 48000,
                44100, 32000, 24000, 22050,
                16000, 12000, 11025, 8000,
                7350, 0, 0, 0
            ]
            let samplingFrequency: Int
            if samplingIndex == 0x0F, let explicit = reader.read(bits: 24) {
                samplingFrequency = explicit
            } else if samplingIndex < frequencies.count {
                samplingFrequency = frequencies[samplingIndex]
            } else {
                samplingFrequency = 0
            }

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.aac.sampling_frequency_hz",
                value: String(samplingFrequency),
                description: "Sampling frequency (Hz)",
                byteRange: nil
            ))

            fields.append(ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.aac.channel_configuration",
                value: String(channelConfig),
                description: "Channel configuration",
                byteRange: nil
            ))

            return fields
        }

        private struct Bitstream {
            private let bytes: [UInt8]
            private var byteIndex: Int = 0
            private var bitIndex: Int = 0

            init(data: [UInt8]) {
                self.bytes = data
            }

            mutating func read(bits count: Int) -> Int? {
                var value = 0
                for _ in 0..<count {
                    guard byteIndex < bytes.count else { return nil }
                    value <<= 1
                    let byte = bytes[byteIndex]
                    let bit = (byte >> (7 - bitIndex)) & 0x01
                    value |= Int(bit)
                    bitIndex += 1
                    if bitIndex == 8 {
                        bitIndex = 0
                        byteIndex += 1
                    }
                }
                return value
            }
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

        private static func decodeSignedFixedPoint(_ value: Int32, fractionalBits: Int) -> Double {
            Double(value) / Double(1 << fractionalBits)
        }

        private static func formatSignedFixedPoint(
            _ value: Int32,
            fractionalBits: Int,
            precision: Int
        ) -> String {
            let formatted = decodeSignedFixedPoint(value, fractionalBits: fractionalBits)
            return String(format: "%.\(precision)f", formatted)
        }

        private static func decodeHandlerName(from data: Data, at offset: Int64) -> ParsedBoxPayload.Field? {
            guard !data.isEmpty else { return nil }
            let nameData: Data
            if let terminatorIndex = data.firstIndex(of: 0) {
                nameData = data.prefix(upTo: terminatorIndex)
            } else {
                nameData = data
            }
            guard !nameData.isEmpty else { return nil }
            guard let name = String(data: nameData, encoding: .utf8) else { return nil }
            let nameEnd = offset + Int64(nameData.count)
            return ParsedBoxPayload.Field(
                name: "handler_name",
                value: name,
                description: "Handler name",
                byteRange: offset..<nameEnd
            )
        }
    }
}
