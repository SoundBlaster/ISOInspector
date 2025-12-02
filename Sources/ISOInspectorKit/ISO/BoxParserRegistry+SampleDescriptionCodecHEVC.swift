import Foundation

extension BoxParserRegistry.DefaultParsers {
    // MARK: - HEVC Sample Entry Helpers

    static func parseHevcConfiguration(reader: RandomAccessReader, box: NestedBox, entryIndex: Int)
        -> [ParsedBoxPayload.Field]
    {
        let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
        guard length > 0,
            let payload = try? readData(
                reader, at: box.payloadRange.lowerBound, count: length,
                end: box.payloadRange.upperBound)
        else { return [] }

        guard payload.count >= 23 else { return [] }

        var fields: [ParsedBoxPayload.Field] = []
        let baseOffset = box.payloadRange.lowerBound

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.configuration_version",
                value: String(payload[0]), description: "HEVC configuration version",
                byteRange: baseOffset..<(baseOffset + 1)))

        let profileSpace = (payload[1] >> 6) & 0x03
        let tierFlag = (payload[1] >> 5) & 0x01
        let profileIDC = payload[1] & 0x1F

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.profile_space",
                value: String(profileSpace), description: "Profile space",
                byteRange: (baseOffset + 1)..<(baseOffset + 2)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.tier_flag",
                value: tierFlag == 0 ? "main" : "high", description: "Tier flag",
                byteRange: (baseOffset + 1)..<(baseOffset + 2)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.profile_idc", value: String(profileIDC),
                description: "Profile IDC", byteRange: (baseOffset + 1)..<(baseOffset + 2)))

        let compatibility = payload[2..<6].reduce(0) { ($0 << 8) | UInt32($1) }
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.profile_compatibility_flags",
                value: String(format: "0x%08X", compatibility),
                description: "Profile compatibility flags",
                byteRange: (baseOffset + 2)..<(baseOffset + 6)))

        let constraintBytes = payload[6..<12]
        let constraintHex = constraintBytes.map { String(format: "%02X", $0) }.joined()
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.constraint_indicator_flags",
                value: "0x\(constraintHex)", description: "Constraint indicator flags",
                byteRange: (baseOffset + 6)..<(baseOffset + 12)))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.level_idc", value: String(payload[12]),
                description: "Level IDC", byteRange: (baseOffset + 12)..<(baseOffset + 13)))

        let lengthSizeMinusOne = payload[21] & 0x03
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.nal_unit_length_bytes",
                value: String(Int(lengthSizeMinusOne) + 1),
                description: "NAL unit length field size",
                byteRange: (baseOffset + 21)..<(baseOffset + 22)))

        let numArrays = Int(payload[22])
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.hevc.nal_arrays", value: String(numArrays),
                description: "Number of NAL unit arrays",
                byteRange: (baseOffset + 22)..<(baseOffset + 23)))

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
                // Array completeness doesn't change metadata but ensures we consume all NALUs.
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
            fields.append(
                ParsedBoxPayload.Field(
                    name: "entries[\(entryIndex)].codec.hevc.\(name).count",
                    value: String(info.count),
                    description: "Number of NAL units of type \(name.uppercased())", byteRange: nil)
            )
            for (index, length) in info.lengths.enumerated() {
                fields.append(
                    ParsedBoxPayload.Field(
                        name: "entries[\(entryIndex)].codec.hevc.\(name)[\(index)].length",
                        value: String(length), description: "NAL unit length", byteRange: nil))
            }
        }

        return fields
    }
}
