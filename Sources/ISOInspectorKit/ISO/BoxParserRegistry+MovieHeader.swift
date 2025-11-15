import Foundation

extension BoxParserRegistry.DefaultParsers {
  @Sendable static func movieHeader(header: BoxHeader, reader: RandomAccessReader) throws
    -> ParsedBoxPayload?
  {
    guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else {
      return nil
    }

    var fields: [ParsedBoxPayload.Field] = []
    let start = header.payloadRange.lowerBound
    let end = header.payloadRange.upperBound

    let availableContent = fullHeader.contentRange.upperBound - fullHeader.contentRange.lowerBound
    let minimumContentLength: Int64 = fullHeader.version == 1 ? 108 : 92
    guard availableContent >= minimumContentLength else { return nil }

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
    let creationTime: UInt64
    let modificationTime: UInt64
    let timescale: UInt32
    let duration: UInt64
    let durationIs64Bit: Bool

    if fullHeader.version == 1 {
      guard let creation = try readUInt64(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "creation_time",
          value: String(creation),
          description: "Movie creation timestamp",
          byteRange: cursor..<(cursor + 8)
        ))
      creationTime = creation
      cursor += 8

      guard let modification = try readUInt64(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "modification_time",
          value: String(modification),
          description: "Last modification timestamp",
          byteRange: cursor..<(cursor + 8)
        ))
      modificationTime = modification
      cursor += 8

      guard let parsedTimescale = try readUInt32(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "timescale",
          value: String(parsedTimescale),
          description: "Time units per second",
          byteRange: cursor..<(cursor + 4)
        ))
      timescale = parsedTimescale
      cursor += 4

      guard let durationValue = try readUInt64(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
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
      fields.append(
        ParsedBoxPayload.Field(
          name: "creation_time",
          value: String(creation),
          description: "Movie creation timestamp",
          byteRange: cursor..<(cursor + 4)
        ))
      creationTime = UInt64(creation)
      cursor += 4

      guard let modification = try readUInt32(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "modification_time",
          value: String(modification),
          description: "Last modification timestamp",
          byteRange: cursor..<(cursor + 4)
        ))
      modificationTime = UInt64(modification)
      cursor += 4

      guard let parsedTimescale = try readUInt32(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "timescale",
          value: String(parsedTimescale),
          description: "Time units per second",
          byteRange: cursor..<(cursor + 4)
        ))
      timescale = parsedTimescale
      cursor += 4

      guard let durationValue = try readUInt32(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
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
    fields.append(
      ParsedBoxPayload.Field(
        name: "rate",
        value: String(format: "%.2f", rateValue),
        description: "Playback rate",
        byteRange: cursor..<(cursor + 4)
      ))
    cursor += 4

    guard let volumeData = try readData(reader, at: cursor, count: 2, end: end) else { return nil }
    let rawVolume = UInt16(volumeData[0]) << 8 | UInt16(volumeData[1])
    let volumeValue = Double(rawVolume) / 256.0
    fields.append(
      ParsedBoxPayload.Field(
        name: "volume",
        value: String(format: "%.2f", volumeValue),
        description: "Playback volume",
        byteRange: cursor..<(cursor + 2)
      ))
    cursor += 2

    guard cursor + 10 <= end else { return nil }
    cursor += 10  // reserved bytes

    struct MatrixEntry {
      let name: String
      let description: String
      let fractionalBits: Int
      let precision: Int
    }

    let matrixEntries: [MatrixEntry] = [
      MatrixEntry(
        name: "matrix.a", description: "Matrix element a (row 1 column 1)", fractionalBits: 16,
        precision: 4),
      MatrixEntry(
        name: "matrix.b", description: "Matrix element b (row 1 column 2)", fractionalBits: 16,
        precision: 4),
      MatrixEntry(
        name: "matrix.u", description: "Matrix element u (row 1 column 3)", fractionalBits: 30,
        precision: 6),
      MatrixEntry(
        name: "matrix.c", description: "Matrix element c (row 2 column 1)", fractionalBits: 16,
        precision: 4),
      MatrixEntry(
        name: "matrix.d", description: "Matrix element d (row 2 column 2)", fractionalBits: 16,
        precision: 4),
      MatrixEntry(
        name: "matrix.v", description: "Matrix element v (row 2 column 3)", fractionalBits: 30,
        precision: 6),
      MatrixEntry(
        name: "matrix.x", description: "Matrix element x (row 3 column 1)", fractionalBits: 16,
        precision: 4),
      MatrixEntry(
        name: "matrix.y", description: "Matrix element y (row 3 column 2)", fractionalBits: 16,
        precision: 4),
      MatrixEntry(
        name: "matrix.w", description: "Matrix element w (row 3 column 3)", fractionalBits: 30,
        precision: 6),
    ]

    var matrixValues: [Double] = []
    for entry in matrixEntries {
      guard let raw = try readUInt32(reader, at: cursor, end: end) else { return nil }
      let signed = Int32(bitPattern: raw)
      let decoded = decodeSignedFixedPoint(signed, fractionalBits: entry.fractionalBits)
      matrixValues.append(decoded)
      fields.append(
        ParsedBoxPayload.Field(
          name: entry.name,
          value: formatSignedFixedPoint(
            signed, fractionalBits: entry.fractionalBits, precision: entry.precision),
          description: entry.description,
          byteRange: cursor..<(cursor + 4)
        ))
      cursor += 4
    }

    guard cursor + 24 <= end else { return nil }
    cursor += 24  // predefined reserved fields

    guard let nextTrack = try readUInt32(reader, at: cursor, end: end) else { return nil }
    fields.append(
      ParsedBoxPayload.Field(
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
}
