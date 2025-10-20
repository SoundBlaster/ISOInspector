import Foundation

extension BoxParserRegistry.DefaultParsers {
    static func parseAvcConfiguration(
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
}
