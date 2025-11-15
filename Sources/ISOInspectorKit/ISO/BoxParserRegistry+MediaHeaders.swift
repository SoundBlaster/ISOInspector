import Foundation

extension BoxParserRegistry.DefaultParsers {
  @Sendable static func mediaHeader(header: BoxHeader, reader: RandomAccessReader) throws
    -> ParsedBoxPayload?
  {
    guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else {
      return nil
    }

    let start = header.payloadRange.lowerBound
    let end = header.payloadRange.upperBound
    let availableContent = fullHeader.contentRange.upperBound - fullHeader.contentRange.lowerBound
    let minimumContentLength: Int64 =
      fullHeader.version == 1 ? 8 + 8 + 4 + 8 + 2 + 2 : 4 + 4 + 4 + 4 + 2 + 2
    guard availableContent >= minimumContentLength else { return nil }

    var fields: [ParsedBoxPayload.Field] = []
    fields.append(
      ParsedBoxPayload.Field(
        name: "version",
        value: String(fullHeader.version),
        description: "Structure version",
        byteRange: start..<(start + 1)
      ))

    fields.append(
      ParsedBoxPayload.Field(
        name: "flags",
        value: String(format: "0x%06X", fullHeader.flags),
        description: "Bit flags",
        byteRange: (start + 1)..<(start + 4)
      ))

    var cursor = fullHeader.contentStart

    if fullHeader.version == 1 {
      guard let creation = try readUInt64(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "creation_time",
          value: String(creation),
          description: "Media creation timestamp",
          byteRange: cursor..<(cursor + 8)
        ))
      cursor += 8

      guard let modification = try readUInt64(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "modification_time",
          value: String(modification),
          description: "Last modification timestamp",
          byteRange: cursor..<(cursor + 8)
        ))
      cursor += 8

      guard let timescale = try readUInt32(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "timescale",
          value: String(timescale),
          description: "Media time units per second",
          byteRange: cursor..<(cursor + 4)
        ))
      cursor += 4

      guard let duration = try readUInt64(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "duration",
          value: String(duration),
          description: "Media duration",
          byteRange: cursor..<(cursor + 8)
        ))
      cursor += 8
    } else {
      guard let creation = try readUInt32(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "creation_time",
          value: String(creation),
          description: "Media creation timestamp",
          byteRange: cursor..<(cursor + 4)
        ))
      cursor += 4

      guard let modification = try readUInt32(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "modification_time",
          value: String(modification),
          description: "Last modification timestamp",
          byteRange: cursor..<(cursor + 4)
        ))
      cursor += 4

      guard let timescale = try readUInt32(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "timescale",
          value: String(timescale),
          description: "Media time units per second",
          byteRange: cursor..<(cursor + 4)
        ))
      cursor += 4

      guard let duration = try readUInt32(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "duration",
          value: String(duration),
          description: "Media duration",
          byteRange: cursor..<(cursor + 4)
        ))
      cursor += 4
    }

    guard let languageRaw = try readUInt16(reader, at: cursor, end: end) else { return nil }
    let languageValue = decodeISO639Language(languageRaw) ?? String(format: "0x%04X", languageRaw)
    fields.append(
      ParsedBoxPayload.Field(
        name: "language",
        value: languageValue,
        description: "ISO-639-2/T language code",
        byteRange: cursor..<(cursor + 2)
      ))
    cursor += 2

    guard let preDefined = try readUInt16(reader, at: cursor, end: end) else { return nil }
    fields.append(
      ParsedBoxPayload.Field(
        name: "pre_defined",
        value: String(preDefined),
        description: "Reserved value",
        byteRange: cursor..<(cursor + 2)
      ))

    return ParsedBoxPayload(fields: fields)
  }

  @Sendable static func soundMediaHeader(header: BoxHeader, reader: RandomAccessReader) throws
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
        name: "version",
        value: String(fullHeader.version),
        description: "Structure version",
        byteRange: start..<(start + 1)
      ))

    fields.append(
      ParsedBoxPayload.Field(
        name: "flags",
        value: String(format: "0x%06X", fullHeader.flags),
        description: "Bit flags",
        byteRange: (start + 1)..<(start + 4)
      ))

    var cursor = fullHeader.contentStart

    guard let balanceRaw = try readInt16(reader, at: cursor, end: end) else { return nil }
    let balance = Double(balanceRaw) / 256.0
    let balanceRange = cursor..<(cursor + 2)
    fields.append(
      ParsedBoxPayload.Field(
        name: "balance",
        value: String(format: "%.2f", balance),
        description: "Audio channel balance (center = 0)",
        byteRange: balanceRange
      ))
    fields.append(
      ParsedBoxPayload.Field(
        name: "balance_raw",
        value: String(Int(balanceRaw)),
        description: "Raw signed 8.8 balance value",
        byteRange: balanceRange
      ))
    cursor += 2

    guard let reserved = try readUInt16(reader, at: cursor, end: end) else { return nil }
    fields.append(
      ParsedBoxPayload.Field(
        name: "reserved",
        value: String(reserved),
        description: "Reserved field",
        byteRange: cursor..<(cursor + 2)
      ))

    let detail = ParsedBoxPayload.SoundMediaHeaderBox(
      version: fullHeader.version,
      flags: fullHeader.flags,
      balance: balance,
      balanceRaw: balanceRaw
    )

    return ParsedBoxPayload(fields: fields, detail: .soundMediaHeader(detail))
  }

  @Sendable static func videoMediaHeader(header: BoxHeader, reader: RandomAccessReader) throws
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
        name: "version",
        value: String(fullHeader.version),
        description: "Structure version",
        byteRange: start..<(start + 1)
      ))

    fields.append(
      ParsedBoxPayload.Field(
        name: "flags",
        value: String(format: "0x%06X", fullHeader.flags),
        description: "Bit flags",
        byteRange: (start + 1)..<(start + 4)
      ))

    var cursor = fullHeader.contentStart

    guard let graphicsMode = try readUInt16(reader, at: cursor, end: end) else { return nil }
    let graphicsRange = cursor..<(cursor + 2)
    let graphicsDescription = describeGraphicsMode(graphicsMode)
    let graphicsValue = graphicsDescription ?? "reserved"
    fields.append(
      ParsedBoxPayload.Field(
        name: "graphics_mode",
        value: graphicsValue,
        description: "Video transfer/compositing mode",
        byteRange: graphicsRange
      ))
    fields.append(
      ParsedBoxPayload.Field(
        name: "graphics_mode_raw",
        value: String(graphicsMode),
        description: "Raw graphics mode value",
        byteRange: graphicsRange
      ))
    cursor += 2

    struct OpcolorEntry {
      let name: String
      let description: String
    }

    let entries: [OpcolorEntry] = [
      OpcolorEntry(name: "opcolor.red", description: "Normalized red overprint color"),
      OpcolorEntry(name: "opcolor.green", description: "Normalized green overprint color"),
      OpcolorEntry(name: "opcolor.blue", description: "Normalized blue overprint color"),
    ]

    var components: [ParsedBoxPayload.VideoMediaHeaderBox.OpcolorComponent] = []
    for entry in entries {
      guard let value = try readUInt16(reader, at: cursor, end: end) else { return nil }
      let range = cursor..<(cursor + 2)
      let normalized = Double(value) / 65535.0
      fields.append(
        ParsedBoxPayload.Field(
          name: entry.name,
          value: String(format: "%.4f", normalized),
          description: entry.description,
          byteRange: range
        ))
      fields.append(
        ParsedBoxPayload.Field(
          name: "\(entry.name)_raw",
          value: String(value),
          description: "Raw \(entry.name) value",
          byteRange: range
        ))
      components.append(
        ParsedBoxPayload.VideoMediaHeaderBox.OpcolorComponent(
          raw: value,
          normalized: normalized
        ))
      cursor += 2
    }

    guard components.count == 3 else { return nil }

    let opcolor = ParsedBoxPayload.VideoMediaHeaderBox.Opcolor(
      red: components[0],
      green: components[1],
      blue: components[2]
    )

    let detail = ParsedBoxPayload.VideoMediaHeaderBox(
      version: fullHeader.version,
      flags: fullHeader.flags,
      graphicsMode: graphicsMode,
      graphicsModeDescription: graphicsDescription,
      opcolor: opcolor
    )

    return ParsedBoxPayload(fields: fields, detail: .videoMediaHeader(detail))
  }
}
