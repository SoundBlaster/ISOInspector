import Foundation

extension BoxParserRegistry.DefaultParsers {
    // MARK: - Elementary Stream Descriptors (ESDS)

    static func parseEsdsConfiguration(reader: RandomAccessReader, box: NestedBox, entryIndex: Int)
        -> [ParsedBoxPayload.Field]
    {
        let length = Int(box.payloadRange.upperBound - box.payloadRange.lowerBound)
        guard length > 0,
            let payload = try? readData(
                reader, at: box.payloadRange.lowerBound, count: length,
                end: box.payloadRange.upperBound)
        else { return [] }

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
                fields.append(
                    contentsOf: parseESDescriptor(
                        payload: payload, start: bodyStart, length: descriptor.length,
                        baseOffset: baseOffset + Int64(bodyStart), entryIndex: entryIndex))
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
        payload: Data, start: Int, length: Int, baseOffset: Int64, entryIndex: Int
    ) -> [ParsedBoxPayload.Field] {
        guard start + length <= payload.count else { return [] }

        var offset = start
        guard offset + 2 <= start + length else { return [] }
        offset += 2  // ES_ID
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
                    payload: payload, start: bodyStart, length: descriptor.length,
                    baseOffset: baseOffset + Int64(bodyStart), entryIndex: entryIndex)
            }

            offset = bodyEnd
        }

        return []
    }

    private static func parseDecoderConfigDescriptor(
        payload: Data, start: Int, length: Int, baseOffset: Int64, entryIndex: Int
    ) -> [ParsedBoxPayload.Field] {
        guard start + length <= payload.count, length >= 13 else { return [] }

        var fields: [ParsedBoxPayload.Field] = []

        let objectType = payload[start]
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.aac.object_type_indication",
                value: String(format: "0x%02X", objectType), description: "Object type indication",
                byteRange: baseOffset..<(baseOffset + 1)))

        var offset = start + 13

        while offset < start + length {
            guard let descriptor = readDescriptorHeader(from: payload, at: offset) else { break }
            let bodyStart = offset + descriptor.headerLength
            let bodyEnd = bodyStart + descriptor.length
            guard bodyEnd <= start + length else { break }

            if descriptor.tag == 0x05 {
                fields.append(
                    contentsOf: parseAudioSpecificConfig(
                        payload: payload, start: bodyStart, length: descriptor.length,
                        baseOffset: baseOffset + Int64(bodyStart), entryIndex: entryIndex))
                break
            }

            offset = bodyEnd
        }

        return fields
    }

    private static func parseAudioSpecificConfig(
        payload: Data, start: Int, length: Int, baseOffset: Int64, entryIndex: Int
    ) -> [ParsedBoxPayload.Field] {
        guard length >= 2, start + length <= payload.count else { return [] }

        let data = payload[start..<(start + length)]
        var reader = Bitstream(data: Array(data))

        guard let rawObjectType = reader.read(bits: 5), let samplingIndex = reader.read(bits: 4),
            let channelConfig = reader.read(bits: 4)
        else { return [] }

        let audioObjectType: Int
        if rawObjectType == 31, let extensionType = reader.read(bits: 6) {
            audioObjectType = 32 + extensionType
        } else {
            audioObjectType = rawObjectType
        }

        var fields: [ParsedBoxPayload.Field] = []
        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.aac.audio_object_type",
                value: String(audioObjectType), description: "AAC audio object type", byteRange: nil
            ))

        let frequencies = [
            96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000, 7350,
            0, 0, 0,
        ]
        let samplingFrequency: Int
        if samplingIndex == 0x0F, let explicit = reader.read(bits: 24) {
            samplingFrequency = explicit
        } else if samplingIndex < frequencies.count {
            samplingFrequency = frequencies[samplingIndex]
        } else {
            samplingFrequency = 0
        }

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.aac.sampling_frequency_hz",
                value: String(samplingFrequency), description: "Sampling frequency (Hz)",
                byteRange: nil))

        fields.append(
            ParsedBoxPayload.Field(
                name: "entries[\(entryIndex)].codec.aac.channel_configuration",
                value: String(channelConfig), description: "Channel configuration", byteRange: nil))

        return fields
    }

    private struct Bitstream {
        private let bytes: [UInt8]
        private var byteIndex: Int = 0
        private var bitIndex: Int = 0

        init(data: [UInt8]) { self.bytes = data }

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
}
