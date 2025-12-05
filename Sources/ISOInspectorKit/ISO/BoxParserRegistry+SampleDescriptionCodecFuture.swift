import Foundation

extension BoxParserRegistry.DefaultParsers {
    static func parseDolbyVisionConfiguration(
        reader: RandomAccessReader, box: NestedBox, entryIndex: Int
    ) -> [ParsedBoxPayload.Field] {
        let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
        guard length > 0,
            let payload = try? readData(
                reader, at: box.payloadRange.lowerBound, count: length,
                end: box.payloadRange.upperBound)
        else { return [] }
        guard payload.count >= 5 else { return [] }

        var fields: [ParsedBoxPayload.Field] = []
        let base = box.payloadRange.lowerBound

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_vision.version_major",
                value: String(payload[0]), description: "Dolby Vision major version",
                byteRange: base..<(base + 1)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_vision.version_minor",
                value: String(payload[1]), description: "Dolby Vision minor version",
                byteRange: (base + 1)..<(base + 2)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_vision.profile",
                value: String(payload[2]), description: "Dolby Vision profile",
                byteRange: (base + 2)..<(base + 3)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_vision.level", value: String(payload[3]),
                description: "Dolby Vision level", byteRange: (base + 3)..<(base + 4)))

        let flags = payload[4]
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_vision.rpu_present",
                value: boolString(flags & 0x80 != 0),
                description: "Indicates whether RPU metadata is present",
                byteRange: (base + 4)..<(base + 5)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_vision.el_present",
                value: boolString(flags & 0x40 != 0),
                description: "Indicates presence of enhancement layer",
                byteRange: (base + 4)..<(base + 5)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_vision.bl_present",
                value: boolString(flags & 0x20 != 0),
                description: "Indicates presence of base layer", byteRange: (base + 4)..<(base + 5))
        )

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_vision.compatibility_id",
                value: String(flags & 0x0F),
                description: "Base layer signal compatibility identifier",
                byteRange: (base + 4)..<(base + 5)))

        return fields
    }

    static func parseAv1Configuration(reader: RandomAccessReader, box: NestedBox, entryIndex: Int)
        -> [ParsedBoxPayload.Field]
    {
        let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
        guard length > 0,
            let payload = try? readData(
                reader, at: box.payloadRange.lowerBound, count: length,
                end: box.payloadRange.upperBound)
        else { return [] }
        guard payload.count >= 4 else { return [] }

        let base = box.payloadRange.lowerBound
        let version = payload[0] & 0x7F
        let profile = (payload[1] >> 5) & 0x07
        let level = payload[1] & 0x1F
        let tierHigh = (payload[2] & 0x80) != 0
        let highBitDepth = (payload[2] & 0x40) != 0
        let twelveBit = (payload[2] & 0x20) != 0
        let monochrome = (payload[2] & 0x10) != 0
        let chromaSubsamplingX = (payload[2] & 0x08) != 0
        let chromaSubsamplingY = (payload[2] & 0x04) != 0
        let chromaSamplePosition = payload[2] & 0x03
        let initialDelayPresent = (payload[3] & 0x10) != 0
        let initialDelayMinusOne = payload[3] & 0x0F

        let bitDepth: Int
        if twelveBit { bitDepth = 12 } else if highBitDepth { bitDepth = 10 } else { bitDepth = 8 }

        let chromaDescription: String
        if monochrome {
            chromaDescription = "monochrome"
        } else if chromaSubsamplingX && chromaSubsamplingY {
            chromaDescription = "4:2:0"
        } else if chromaSubsamplingX {
            chromaDescription = "4:2:2"
        } else {
            chromaDescription = "4:4:4"
        }

        let chromaPositionDescription: String
        switch chromaSamplePosition {
        case 0: chromaPositionDescription = "unspecified"
        case 1: chromaPositionDescription = "vertical"
        case 2: chromaPositionDescription = "colocated"
        default: chromaPositionDescription = "reserved"
        }

        var fields: [ParsedBoxPayload.Field] = []

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.av1.version", value: String(version),
                description: "AV1 configuration version", byteRange: base..<(base + 1)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.av1.profile", value: String(profile),
                description: "Sequence profile", byteRange: (base + 1)..<(base + 2)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.av1.level", value: String(level),
                description: "Sequence level index", byteRange: (base + 1)..<(base + 2)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.av1.tier", value: tierHigh ? "high" : "main",
                description: "Sequence tier flag", byteRange: (base + 2)..<(base + 3)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.av1.bit_depth", value: String(bitDepth),
                description: "Decoded bit depth", byteRange: (base + 2)..<(base + 3)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.av1.monochrome", value: boolString(monochrome),
                description: "Indicates monochrome sequence", byteRange: (base + 2)..<(base + 3)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.av1.chroma_subsampling",
                value: chromaDescription, description: "Chroma subsampling layout",
                byteRange: (base + 2)..<(base + 3)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.av1.chroma_sample_position",
                value: chromaPositionDescription, description: "Chroma sample positioning",
                byteRange: (base + 2)..<(base + 3)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.av1.initial_presentation_delay_present",
                value: boolString(initialDelayPresent),
                description: "Signals presence of initial presentation delay",
                byteRange: (base + 3)..<(base + 4)))

        if initialDelayPresent {
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].codec.av1.initial_presentation_delay_minus_one",
                    value: String(initialDelayMinusOne),
                    description: "Initial presentation delay minus one",
                    byteRange: (base + 3)..<(base + 4)))
        }

        let configOBULength = max(0, payload.count - 4)
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.av1.config_obu_length",
                value: String(configOBULength),
                description: "Length of appended configuration OBUs in bytes",
                byteRange: configOBULength > 0 ? (base + 4)..<(base + Int64(payload.count)) : nil))

        return fields
    }

    static func parseVp9Configuration(reader: RandomAccessReader, box: NestedBox, entryIndex: Int)
        -> [ParsedBoxPayload.Field]
    {
        let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
        guard length > 0,
            let payload = try? readData(
                reader, at: box.payloadRange.lowerBound, count: length,
                end: box.payloadRange.upperBound)
        else { return [] }
        guard payload.count >= 12 else { return [] }

        let base = box.payloadRange.lowerBound
        let profile = payload[4]
        let level = payload[5]
        let colourRange = payload[6]
        let bitDepthCode = (colourRange >> 4) & 0x0F
        let chromaCode = (colourRange >> 1) & 0x07
        let videoFullRange = (colourRange & 0x01) != 0

        let bitDepth: Int
        switch bitDepthCode {
        case 0: bitDepth = 8
        case 1: bitDepth = 10
        case 2: bitDepth = 12
        default: bitDepth = 0
        }

        let chromaDescription: String
        switch chromaCode {
        case 0: chromaDescription = "4:2:0"
        case 1: chromaDescription = "4:2:2"
        case 2: chromaDescription = "4:4:4"
        case 3: chromaDescription = "4:2:0 (colocated)"
        default: chromaDescription = "reserved"
        }

        let codecInitLength = UInt16(payload[10]) << 8 | UInt16(payload[11])

        var fields: [ParsedBoxPayload.Field] = []
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.vp9.profile", value: String(profile),
                description: "VP9 profile", byteRange: (base + 4)..<(base + 5)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.vp9.level", value: String(level),
                description: "VP9 level", byteRange: (base + 5)..<(base + 6)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.vp9.bit_depth", value: String(bitDepth),
                description: "Decoded bit depth", byteRange: (base + 6)..<(base + 7)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.vp9.chroma_subsampling",
                value: chromaDescription, description: "Chroma subsampling scheme",
                byteRange: (base + 6)..<(base + 7)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.vp9.video_full_range",
                value: boolString(videoFullRange), description: "Video full range flag",
                byteRange: (base + 6)..<(base + 7)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.vp9.colour_primaries",
                value: String(payload[7]), description: "Colour primaries",
                byteRange: (base + 7)..<(base + 8)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.vp9.transfer_characteristics",
                value: String(payload[8]), description: "Transfer characteristics",
                byteRange: (base + 8)..<(base + 9)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.vp9.matrix_coefficients",
                value: String(payload[9]), description: "Matrix coefficients",
                byteRange: (base + 9)..<(base + 10)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.vp9.codec_init_bytes",
                value: String(codecInitLength), description: "Codec initialization bytes length",
                byteRange: (base + 10)..<(base + 12)))

        return fields
    }

    static func parseDolbyAC4Configuration(
        reader: RandomAccessReader, box: NestedBox, entryIndex: Int
    ) -> [ParsedBoxPayload.Field] {
        let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
        guard length > 0,
            let payload = try? readData(
                reader, at: box.payloadRange.lowerBound, count: length,
                end: box.payloadRange.upperBound)
        else { return [] }
        guard !payload.isEmpty else { return [] }

        var bitReader = BitReader(data: payload)
        guard let dsiVersion = bitReader.read(bits: 3),
            let bitstreamVersion = bitReader.read(bits: 7),
            let sampleRateIndex = bitReader.read(bits: 1),
            let frameRateIndex = bitReader.read(bits: 4),
            let presentationCount = bitReader.read(bits: 9),
            let bitRateMode = bitReader.read(bits: 2), let bitRate = bitReader.read(bits: 32),
            let bitRatePrecision = bitReader.read(bits: 32)
        else { return [] }

        var fields: [ParsedBoxPayload.Field] = []
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_ac4.dsi_version",
                value: String(dsiVersion), description: "AC-4 decoder specific information version",
                byteRange: nil))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_ac4.bitstream_version",
                value: String(bitstreamVersion), description: "Bitstream version", byteRange: nil))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_ac4.sample_rate_index",
                value: String(sampleRateIndex), description: "Sample rate index", byteRange: nil))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_ac4.frame_rate_index",
                value: String(frameRateIndex), description: "Frame rate index", byteRange: nil))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_ac4.presentation_count",
                value: String(presentationCount), description: "Number of presentations",
                byteRange: nil))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_ac4.bit_rate_mode",
                value: String(bitRateMode), description: "Bit rate mode", byteRange: nil))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_ac4.bit_rate", value: String(bitRate),
                description: "Nominal bit rate", byteRange: nil))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.dolby_ac4.bit_rate_precision",
                value: String(bitRatePrecision), description: "Bit rate precision", byteRange: nil))

        return fields
    }

    static func parseMpegHConfiguration(reader: RandomAccessReader, box: NestedBox, entryIndex: Int)
        -> [ParsedBoxPayload.Field]
    {
        let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
        guard length > 0,
            let payload = try? readData(
                reader, at: box.payloadRange.lowerBound, count: length,
                end: box.payloadRange.upperBound)
        else { return [] }
        guard payload.count >= 8 else { return [] }

        let base = box.payloadRange.lowerBound
        var fields: [ParsedBoxPayload.Field] = []

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.mpeg_h.configuration_version",
                value: String(payload[0]), description: "MPEG-H configuration version",
                byteRange: base..<(base + 1)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.mpeg_h.profile_level_indication",
                value: String(payload[1]), description: "Profile level indication",
                byteRange: (base + 1)..<(base + 2)))

        let referenceLayout = UInt16(payload[2]) << 8 | UInt16(payload[3])
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.mpeg_h.reference_channel_layout",
                value: String(referenceLayout), description: "Reference channel layout",
                byteRange: (base + 2)..<(base + 4)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.mpeg_h.compatible_set_indication",
                value: String(payload[4]), description: "Compatible set indication",
                byteRange: (base + 4)..<(base + 5)))

        guard payload.count >= 9 else { return fields }
        let compatibilitySet =
            UInt32(payload[5]) << 24 | UInt32(payload[6]) << 16 | UInt32(payload[7]) << 8
            | UInt32(payload[8])
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.mpeg_h.general_profile_compatibility_set",
                value: String(compatibilitySet), description: "General profile compatibility set",
                byteRange: (base + 5)..<(base + 9)))

        return fields
    }
}

private struct BitReader {
    private let data: [UInt8]
    private var byteIndex: Int = 0
    private var bitIndex: Int = 0

    init(data: Data) { self.data = Array(data) }

    init(data: [UInt8]) { self.data = data }

    mutating func read(bits count: Int) -> UInt64? {
        guard count >= 0 else { return nil }
        var value: UInt64 = 0
        for _ in 0..<count {
            guard byteIndex < data.count else { return nil }
            let currentByte = data[byteIndex]
            let bit = (currentByte >> (7 - bitIndex)) & 0x01
            value = (value << 1) | UInt64(bit)
            bitIndex += 1
            if bitIndex == 8 {
                bitIndex = 0
                byteIndex += 1
            }
        }
        return value
    }
}
