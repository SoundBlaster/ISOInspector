import XCTest
@testable import ISOInspectorKit

final class StsdSampleDescriptionParserTests: XCTestCase {
    func testParsesVisualAndAudioSampleEntries() throws {
        let visualEntry = makeVisualSampleEntry(width: 1920, height: 1080, dataReferenceIndex: 1)
        let audioEntry = makeAudioSampleEntry(channelCount: 2, sampleSize: 16, sampleRate: 48_000, dataReferenceIndex: 2)
        let fieldsByName = try parseFields(entries: [visualEntry, audioEntry])

        XCTAssertEqual(fieldsByName["entry_count"]?.value, "2")
        XCTAssertEqual(fieldsByName["entries[0].format"]?.value, "avc1")
        XCTAssertEqual(fieldsByName["entries[0].byte_length"]?.value, "86")
        XCTAssertEqual(fieldsByName["entries[0].data_reference_index"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].width"]?.value, "1920")
        XCTAssertEqual(fieldsByName["entries[0].height"]?.value, "1080")

        XCTAssertEqual(fieldsByName["entries[1].format"]?.value, "mp4a")
        XCTAssertEqual(fieldsByName["entries[1].byte_length"]?.value, "36")
        XCTAssertEqual(fieldsByName["entries[1].data_reference_index"]?.value, "2")
        XCTAssertEqual(fieldsByName["entries[1].channelcount"]?.value, "2")
        XCTAssertEqual(fieldsByName["entries[1].samplesize"]?.value, "16")
        XCTAssertEqual(fieldsByName["entries[1].samplerate"]?.value, "48000")
    }

    func testParsesAvcCodecMetadata() throws {
        let avcC = makeAvcConfigurationBox(
            profileIndication: 0x4D,
            profileCompatibility: 0x40,
            levelIndication: 0x1F,
            nalLengthSize: 4,
            sequenceParameterSets: [Data([0x67, 0x64, 0x00, 0x1F])],
            pictureParameterSets: [Data([0x68, 0xEB, 0xEF])]
        )
        let entry = makeVisualSampleEntry(
            width: 1280,
            height: 720,
            dataReferenceIndex: 1,
            additionalBoxes: [avcC]
        )

        let fieldsByName = try parseFields(entries: [entry])

        XCTAssertEqual(fieldsByName["entries[0].codec.avc.configuration_version"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].codec.avc.profile_indication"]?.value, "0x4D")
        XCTAssertEqual(fieldsByName["entries[0].codec.avc.profile_compatibility"]?.value, "0x40")
        XCTAssertEqual(fieldsByName["entries[0].codec.avc.level_indication"]?.value, "31")
        XCTAssertEqual(fieldsByName["entries[0].codec.avc.nal_unit_length_bytes"]?.value, "4")
        XCTAssertEqual(fieldsByName["entries[0].codec.avc.sequence_parameter_sets.count"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].codec.avc.sequence_parameter_sets[0].length"]?.value, "4")
        XCTAssertEqual(fieldsByName["entries[0].codec.avc.picture_parameter_sets.count"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].codec.avc.picture_parameter_sets[0].length"]?.value, "3")
    }

    func testParsesHevcCodecMetadata() throws {
        let hvcC = makeHevcConfigurationBox(
            profileSpace: 0,
            tierFlag: 1,
            profileIDC: 1,
            levelIDC: 120,
            nalLengthSize: 4,
            vpsNalUnits: [Data([0x40, 0x01])],
            spsNalUnits: [Data([0x42, 0x01, 0x01])],
            ppsNalUnits: [Data([0x44, 0x01])]
        )
        let entry = makeVisualSampleEntry(
            format: "hvc1",
            width: 1920,
            height: 1080,
            dataReferenceIndex: 1,
            additionalBoxes: [hvcC]
        )

        let fieldsByName = try parseFields(entries: [entry])

        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.configuration_version"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.profile_space"]?.value, "0")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.tier_flag"]?.value, "high")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.profile_idc"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.level_idc"]?.value, "120")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.constraint_indicator_flags"]?.value, "0x000000000000")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.nal_unit_length_bytes"]?.value, "4")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.vps.count"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.vps[0].length"]?.value, "2")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.sps.count"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.sps[0].length"]?.value, "3")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.pps.count"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].codec.hevc.pps[0].length"]?.value, "2")
    }

    func testParsesEsdsAudioSpecificConfig() throws {
        let esds = makeEsdsBox(
            objectTypeIndication: 0x40,
            audioObjectType: 2,
            samplingFrequencyIndex: 3,
            channelConfiguration: 2
        )
        let entry = makeAudioSampleEntry(
            channelCount: 2,
            sampleSize: 16,
            sampleRate: 48_000,
            dataReferenceIndex: 1,
            additionalBoxes: [esds]
        )

        let fieldsByName = try parseFields(entries: [entry])

        XCTAssertEqual(fieldsByName["entries[0].codec.aac.object_type_indication"]?.value, "0x40")
        XCTAssertEqual(fieldsByName["entries[0].codec.aac.audio_object_type"]?.value, "2")
        XCTAssertEqual(fieldsByName["entries[0].codec.aac.sampling_frequency_hz"]?.value, "48000")
        XCTAssertEqual(fieldsByName["entries[0].codec.aac.channel_configuration"]?.value, "2")
    }

    func testParsesEncryptedSampleEntryAndPreservesCodecMetadata() throws {
        let avcC = makeAvcConfigurationBox(
            profileIndication: 0x64,
            profileCompatibility: 0x00,
            levelIndication: 0x1F,
            nalLengthSize: 4,
            sequenceParameterSets: [Data([0x67, 0x64, 0x00, 0x1F])],
            pictureParameterSets: [Data([0x68, 0xEE, 0x3C])]
        )
        let sinf = makeSinfBox(
            originalFormat: "avc1",
            schemeType: "cenc",
            schemeVersion: 0x00010000,
            defaultIsProtected: 1,
            defaultPerSampleIVSize: 8,
            defaultKID: Array(repeating: 0xAB, count: 16)
        )
        let entry = makeVisualSampleEntry(
            format: "encv",
            width: 1920,
            height: 1080,
            dataReferenceIndex: 1,
            additionalBoxes: [sinf, avcC]
        )

        let fieldsByName = try parseFields(entries: [entry])

        XCTAssertEqual(fieldsByName["entries[0].format"]?.value, "encv")
        XCTAssertEqual(fieldsByName["entries[0].encryption.original_format"]?.value, "avc1")
        XCTAssertEqual(fieldsByName["entries[0].encryption.scheme_type"]?.value, "cenc")
        XCTAssertEqual(fieldsByName["entries[0].encryption.scheme_version"]?.value, "0x00010000")
        XCTAssertEqual(fieldsByName["entries[0].encryption.is_protected"]?.value, "true")
        XCTAssertEqual(fieldsByName["entries[0].encryption.per_sample_iv_size"]?.value, "8")
        XCTAssertEqual(fieldsByName["entries[0].encryption.default_kid"]?.value, "abababababababababababababababab")
        XCTAssertEqual(fieldsByName["entries[0].codec.avc.sequence_parameter_sets.count"]?.value, "1")
        XCTAssertEqual(fieldsByName["entries[0].codec.avc.picture_parameter_sets.count"]?.value, "1")
    }

    private func parseFields(entries: [Data]) throws -> [String: ParsedBoxPayload.Field] {
        let payload = makeStsdPayload(entries: entries)
        let totalSize = 8 + payload.count
        var data = Data(count: totalSize)
        data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
        data.replaceSubrange(4..<8, with: Data("stsd".utf8))
        data.replaceSubrange(8..<totalSize, with: payload)

        let header = BoxHeader(
            type: try FourCharCode("stsd"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )
        let reader = InMemoryRandomAccessReader(data: data)

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))
        return Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
    }

    private func makeStsdPayload(entries: [Data]) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)
        for entry in entries {
            payload.append(entry)
        }
        return payload
    }

    private func makeVisualSampleEntry(
        format: String = "avc1",
        width: UInt16,
        height: UInt16,
        dataReferenceIndex: UInt16,
        additionalBoxes: [Data] = []
    ) -> Data {
        var entry = Data()
        entry.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // size placeholder
        entry.append(contentsOf: Data(format.utf8))
        entry.append(Data(repeating: 0, count: 6)) // reserved
        entry.append(contentsOf: dataReferenceIndex.bigEndianBytes)
        entry.append(contentsOf: UInt16(0).bigEndianBytes) // pre_defined
        entry.append(contentsOf: UInt16(0).bigEndianBytes) // reserved
        entry.append(Data(repeating: 0, count: 12)) // pre_defined[3]
        entry.append(contentsOf: width.bigEndianBytes)
        entry.append(contentsOf: height.bigEndianBytes)
        entry.append(contentsOf: UInt32(0x00480000).bigEndianBytes) // horizresolution
        entry.append(contentsOf: UInt32(0x00480000).bigEndianBytes) // vertresolution
        entry.append(contentsOf: UInt32(0).bigEndianBytes) // reserved
        entry.append(contentsOf: UInt16(1).bigEndianBytes) // frame_count
        var compressorName = Data([3])
        compressorName.append(contentsOf: Data("AVC".utf8))
        compressorName.append(Data(repeating: 0, count: 32 - compressorName.count))
        entry.append(compressorName)
        entry.append(contentsOf: UInt16(0x0018).bigEndianBytes) // depth
        entry.append(contentsOf: UInt16(0xFFFF).bigEndianBytes) // pre_defined

        for box in additionalBoxes {
            entry.append(box)
        }

        let size = UInt32(entry.count)
        entry.replaceSubrange(0..<4, with: size.bigEndianBytes)
        return entry
    }

    private func makeAudioSampleEntry(
        channelCount: UInt16,
        sampleSize: UInt16,
        sampleRate: UInt32,
        dataReferenceIndex: UInt16,
        additionalBoxes: [Data] = []
    ) -> Data {
        var entry = Data()
        entry.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // size placeholder
        entry.append(contentsOf: Data("mp4a".utf8))
        entry.append(Data(repeating: 0, count: 6))
        entry.append(contentsOf: dataReferenceIndex.bigEndianBytes)
        entry.append(contentsOf: UInt32(0).bigEndianBytes)
        entry.append(contentsOf: UInt32(0).bigEndianBytes)
        entry.append(contentsOf: channelCount.bigEndianBytes)
        entry.append(contentsOf: sampleSize.bigEndianBytes)
        entry.append(contentsOf: UInt16(0).bigEndianBytes)
        entry.append(contentsOf: UInt16(0).bigEndianBytes)
        entry.append(contentsOf: UInt32(sampleRate << 16).bigEndianBytes)

        for box in additionalBoxes {
            entry.append(box)
        }

        let size = UInt32(entry.count)
        entry.replaceSubrange(0..<4, with: size.bigEndianBytes)
        return entry
    }

    private func makeAvcConfigurationBox(
        configurationVersion: UInt8 = 1,
        profileIndication: UInt8,
        profileCompatibility: UInt8,
        levelIndication: UInt8,
        nalLengthSize: UInt8,
        sequenceParameterSets: [Data],
        pictureParameterSets: [Data]
    ) -> Data {
        var payload = Data()
        payload.append(configurationVersion)
        payload.append(profileIndication)
        payload.append(profileCompatibility)
        payload.append(levelIndication)
        let lengthMinusOne = UInt8(max(1, nalLengthSize) - 1) & 0x03
        payload.append(0xFC | lengthMinusOne)
        let spsCount = UInt8(sequenceParameterSets.count & 0x1F)
        payload.append(0xE0 | spsCount)
        for sps in sequenceParameterSets {
            payload.append(contentsOf: UInt16(sps.count).bigEndianBytes)
            payload.append(sps)
        }
        payload.append(UInt8(pictureParameterSets.count))
        for pps in pictureParameterSets {
            payload.append(contentsOf: UInt16(pps.count).bigEndianBytes)
            payload.append(pps)
        }

        return makeBox(type: "avcC", payload: payload)
    }

    private func makeHevcConfigurationBox(
        profileSpace: UInt8,
        tierFlag: UInt8,
        profileIDC: UInt8,
        levelIDC: UInt8,
        nalLengthSize: UInt8,
        vpsNalUnits: [Data],
        spsNalUnits: [Data],
        ppsNalUnits: [Data]
    ) -> Data {
        var payload = Data()
        payload.append(1) // configurationVersion
        let profileByte = (profileSpace & 0x03) << 6 | ((tierFlag & 0x01) << 5) | (profileIDC & 0x1F)
        payload.append(profileByte)
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // profile compatibility flags
        payload.append(contentsOf: Data(repeating: 0x00, count: 6)) // constraint indicator flags
        payload.append(levelIDC)
        payload.append(contentsOf: UInt16(0xF000).bigEndianBytes) // reserved + min spatial segmentation idc
        payload.append(0xFC) // parallelismType (reserved pattern with zero value)
        payload.append(0xFC) // chroma format (reserved pattern with zero value)
        payload.append(0xF8) // bit depth luma - 8 (zero)
        payload.append(0xF8) // bit depth chroma - 8 (zero)
        payload.append(contentsOf: UInt16(0).bigEndianBytes) // avgFrameRate
        let lengthMinusOne = UInt8(max(1, nalLengthSize) - 1) & 0x03
        payload.append(0x00 | lengthMinusOne) // constantFrameRate(0), numTemporalLayers(0), temporalIdNested(0)

        let arrays: [(UInt8, [Data])] = [
            (32, vpsNalUnits),
            (33, spsNalUnits),
            (34, ppsNalUnits)
        ]

        payload.append(UInt8(arrays.count))
        for (nalType, nalUnits) in arrays {
            guard !nalUnits.isEmpty else { continue }
            payload.append(0x80 | (nalType & 0x3F))
            payload.append(contentsOf: UInt16(nalUnits.count).bigEndianBytes)
            for unit in nalUnits {
                payload.append(contentsOf: UInt16(unit.count).bigEndianBytes)
                payload.append(unit)
            }
        }

        return makeBox(type: "hvcC", payload: payload)
    }

    private func makeEsdsBox(
        objectTypeIndication: UInt8,
        audioObjectType: Int,
        samplingFrequencyIndex: Int,
        channelConfiguration: Int
    ) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags

        var esDescriptor = Data()
        esDescriptor.append(contentsOf: UInt16(1).bigEndianBytes) // ES_ID
        esDescriptor.append(0x00) // flags byte

        var decoderConfig = Data()
        decoderConfig.append(objectTypeIndication)
        decoderConfig.append(0x15) // streamType audio, upstream=0, reserved=1
        decoderConfig.append(contentsOf: [0x00, 0x00, 0x00]) // bufferSizeDB
        decoderConfig.append(contentsOf: UInt32(0).bigEndianBytes) // maxBitrate
        decoderConfig.append(contentsOf: UInt32(0).bigEndianBytes) // avgBitrate

        let audioSpecific = makeAudioSpecificConfig(
            audioObjectType: audioObjectType,
            samplingFrequencyIndex: samplingFrequencyIndex,
            channelConfiguration: channelConfiguration
        )
        decoderConfig.append(0x05)
        decoderConfig.append(contentsOf: encodeDescriptorLength(audioSpecific.count))
        decoderConfig.append(audioSpecific)

        esDescriptor.append(0x04)
        esDescriptor.append(contentsOf: encodeDescriptorLength(decoderConfig.count))
        esDescriptor.append(decoderConfig)

        esDescriptor.append(0x06)
        esDescriptor.append(contentsOf: encodeDescriptorLength(1))
        esDescriptor.append(0x02)

        payload.append(0x03)
        payload.append(contentsOf: encodeDescriptorLength(esDescriptor.count))
        payload.append(esDescriptor)

        return makeBox(type: "esds", payload: payload)
    }

    private func makeSinfBox(
        originalFormat: String,
        schemeType: String,
        schemeVersion: UInt32,
        defaultIsProtected: UInt8,
        defaultPerSampleIVSize: UInt8,
        defaultKID: [UInt8]
    ) -> Data {
        let frmaPayload = Data(originalFormat.utf8)
        let frma = makeBox(type: "frma", payload: frmaPayload)

        var schmPayload = Data()
        schmPayload.append(0x00)
        schmPayload.append(contentsOf: [0x00, 0x00, 0x00])
        schmPayload.append(contentsOf: Data(schemeType.utf8))
        schmPayload.append(contentsOf: schemeVersion.bigEndianBytes)
        let schm = makeBox(type: "schm", payload: schmPayload)

        var tencPayload = Data()
        tencPayload.append(0x00)
        tencPayload.append(contentsOf: [0x00, 0x00, 0x00])
        tencPayload.append(defaultIsProtected)
        tencPayload.append(defaultPerSampleIVSize)
        tencPayload.append(contentsOf: defaultKID)
        let tenc = makeBox(type: "tenc", payload: tencPayload)

        let schi = makeBox(type: "schi", payload: tenc)

        let sinfPayload = frma + schm + schi
        return makeBox(type: "sinf", payload: sinfPayload)
    }

    private func makeAudioSpecificConfig(
        audioObjectType: Int,
        samplingFrequencyIndex: Int,
        channelConfiguration: Int
    ) -> Data {
        var bits: [UInt8] = []
        func appendBits(_ value: Int, count: Int) {
            for shift in stride(from: count - 1, through: 0, by: -1) {
                let bit = UInt8((value >> shift) & 1)
                bits.append(bit)
            }
        }

        var objectType = audioObjectType
        if objectType >= 32 {
            objectType = 32
        }

        appendBits(objectType, count: 5)
        appendBits(samplingFrequencyIndex, count: 4)
        appendBits(channelConfiguration, count: 4)

        var data = Data()
        var currentByte: UInt8 = 0
        for (index, bit) in bits.enumerated() {
            currentByte = (currentByte << 1) | bit
            if index % 8 == 7 {
                data.append(currentByte)
                currentByte = 0
            }
        }
        if bits.count % 8 != 0 {
            currentByte <<= UInt8(8 - (bits.count % 8))
            data.append(currentByte)
        }

        return data
    }

    private func makeBox(type: String, payload: Data) -> Data {
        var box = Data()
        let size = UInt32(8 + payload.count)
        box.append(contentsOf: size.bigEndianBytes)
        box.append(contentsOf: Data(type.utf8))
        box.append(payload)
        return box
    }

    private func encodeDescriptorLength(_ length: Int) -> [UInt8] {
        var remaining = length
        var bytes: [UInt8] = []
        var stack: [UInt8] = []
        repeat {
            let value = UInt8(remaining & 0x7F)
            stack.append(value)
            remaining >>= 7
        } while remaining > 0
        for index in stack.indices.reversed() {
            var byte = stack[index]
            if index != stack.startIndex {
                byte |= 0x80
            }
            bytes.append(byte)
        }
        return bytes
    }
}

private extension UInt16 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}

private extension UInt32 {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: bigEndian, Array.init)
    }
}
