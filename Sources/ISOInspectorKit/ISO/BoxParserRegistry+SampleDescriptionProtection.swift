import Foundation

extension BoxParserRegistry.DefaultParsers {
  static func parseCodecSpecificFields(
    format: FourCharCode,
    boxes: [NestedBox],
    reader: RandomAccessReader,
    entryIndex: Int
  ) -> [ParsedBoxPayload.Field] {
    var fields: [ParsedBoxPayload.Field] = []

    if avcSampleEntryTypes.contains(format),
      let avcBox = boxes.first(where: { $0.type.rawValue == "avcC" })
    {
      fields.append(
        contentsOf: parseAvcConfiguration(
          reader: reader,
          box: avcBox,
          entryIndex: entryIndex
        ))
    }

    if hevcSampleEntryTypes.contains(format),
      let hevcBox = boxes.first(where: { $0.type.rawValue == "hvcC" })
    {
      fields.append(
        contentsOf: parseHevcConfiguration(
          reader: reader,
          box: hevcBox,
          entryIndex: entryIndex
        ))
    }

    if format.rawValue == "mp4a",
      let esdsBox = boxes.first(where: { $0.type.rawValue == "esds" })
    {
      fields.append(
        contentsOf: parseEsdsConfiguration(
          reader: reader,
          box: esdsBox,
          entryIndex: entryIndex
        ))
    }

    if let dolbyVisionBox = boxes.first(where: { $0.type.rawValue == "dvvC" }) {
      fields.append(
        contentsOf: parseDolbyVisionConfiguration(
          reader: reader,
          box: dolbyVisionBox,
          entryIndex: entryIndex
        ))
    }

    if format.rawValue == "av01",
      let av1Box = boxes.first(where: { $0.type.rawValue == "av1C" })
    {
      fields.append(
        contentsOf: parseAv1Configuration(
          reader: reader,
          box: av1Box,
          entryIndex: entryIndex
        ))
    }

    if ["vp09", "vp08"].contains(format.rawValue),
      let vp9Box = boxes.first(where: { $0.type.rawValue == "vpcC" })
    {
      fields.append(
        contentsOf: parseVp9Configuration(
          reader: reader,
          box: vp9Box,
          entryIndex: entryIndex
        ))
    }

    if format.rawValue == "ac-4",
      let ac4Box = boxes.first(where: { $0.type.rawValue == "dac4" })
    {
      fields.append(
        contentsOf: parseDolbyAC4Configuration(
          reader: reader,
          box: ac4Box,
          entryIndex: entryIndex
        ))
    }

    if ["mha1", "mhm1"].contains(format.rawValue),
      let mpegHBox = boxes.first(where: { $0.type.rawValue == "mhaC" })
    {
      fields.append(
        contentsOf: parseMpegHConfiguration(
          reader: reader,
          box: mpegHBox,
          entryIndex: entryIndex
        ))
    }

    return fields
  }

  static func parseProtectedSampleEntry(
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
      let format = try? reader.readFourCC(at: frma.payloadRange.lowerBound)
    {
      originalFormat = format
      fields.append(
        ParsedBoxPayload.Field(
          name: "entries[\(entryIndex)].encryption.original_format",
          value: format.rawValue,
          description: "Original codec format before protection",
          byteRange: frma.payloadRange
        ))
    }

    if let schm = sinfChildren.first(where: { $0.type.rawValue == "schm" }) {
      fields.append(
        contentsOf: parseSchemeInformation(
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
        fields.append(
          contentsOf: parseTrackEncryption(
            reader: reader,
            box: tenc,
            entryIndex: entryIndex
          ))
      }
    }

    return (fields, originalFormat)
  }

  static func parseSchemeInformation(
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
      )
    else { return [] }

    guard payload.count >= 8 else { return [] }

    var fields: [ParsedBoxPayload.Field] = []
    guard payload.count >= 8 else { return fields }

    let schemeTypeData = payload[4..<8]
    if let schemeType = String(bytes: schemeTypeData, encoding: .ascii) {
      fields.append(
        ParsedBoxPayload.Field(
          name: "entries[\(entryIndex)].encryption.scheme_type",
          value: schemeType,
          description: "Protection scheme identifier",
          byteRange: (box.payloadRange.lowerBound + 4)..<(box.payloadRange.lowerBound + 8)
        ))
    }

    if payload.count >= 12 {
      let schemeVersion = payload[8..<12].reduce(0) { ($0 << 8) | UInt32($1) }
      fields.append(
        ParsedBoxPayload.Field(
          name: "entries[\(entryIndex)].encryption.scheme_version",
          value: String(format: "0x%08X", schemeVersion),
          description: "Protection scheme version",
          byteRange: (box.payloadRange.lowerBound + 8)..<(box.payloadRange.lowerBound + 12)
        ))
    }

    if payload.count > 12 {
      let uriData = payload[12..<payload.count]
      if let uri = String(bytes: uriData, encoding: .utf8), !uri.isEmpty {
        fields.append(
          ParsedBoxPayload.Field(
            name: "entries[\(entryIndex)].encryption.scheme_uri",
            value: uri,
            description: "Protection scheme URI",
            byteRange: (box.payloadRange.lowerBound + 12)..<box.payloadRange.upperBound
          ))
      }
    }

    return fields
  }

  static func parseTrackEncryption(
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
      )
    else { return [] }

    guard payload.count >= 6 else { return [] }

    let defaultIsProtected = payload[4]
    let defaultPerSampleIVSize = payload[5]

    var fields: [ParsedBoxPayload.Field] = []
    fields.append(
      ParsedBoxPayload.Field(
        name: "entries[\(entryIndex)].encryption.is_protected",
        value: defaultIsProtected != 0 ? "true" : "false",
        description: "Indicates whether samples are encrypted",
        byteRange: (box.payloadRange.lowerBound + 4)..<(box.payloadRange.lowerBound + 5)
      ))

    fields.append(
      ParsedBoxPayload.Field(
        name: "entries[\(entryIndex)].encryption.per_sample_iv_size",
        value: String(defaultPerSampleIVSize),
        description: "Size of per-sample IV in bytes (0 for constant)",
        byteRange: (box.payloadRange.lowerBound + 5)..<(box.payloadRange.lowerBound + 6)
      ))

    if payload.count >= 22 {
      let kidRange = (box.payloadRange.lowerBound + 6)..<(box.payloadRange.lowerBound + 22)
      let kid = payload[6..<22].map { String(format: "%02x", $0) }.joined()
      fields.append(
        ParsedBoxPayload.Field(
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
        fields.append(
          ParsedBoxPayload.Field(
            name: "entries[\(entryIndex)].encryption.constant_iv",
            value: ivData,
            description: "Constant IV for samples when per-sample IV size is zero",
            byteRange: (box.payloadRange.lowerBound + 23)..<(box.payloadRange.lowerBound
              + Int64(constantIVEnd))
          ))
      }
    }

    return fields
  }
}
