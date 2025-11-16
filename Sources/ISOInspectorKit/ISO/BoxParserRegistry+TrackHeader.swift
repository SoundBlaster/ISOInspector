import Foundation

extension BoxParserRegistry.DefaultParsers {
  // Rationale: Parser for tkhd box with many optional fields per ISO/IEC 14496-12 specification.
  // @todo #A7 Consider extracting version-specific field parsing into helper methods.
  // swiftlint:disable:next function_body_length
  @Sendable static func trackHeader(header: BoxHeader, reader: RandomAccessReader) throws
    -> ParsedBoxPayload?
  {
    guard let fullHeader = try FullBoxReader.read(header: header, reader: reader) else {
      return nil
    }

    let start = header.payloadRange.lowerBound
    let end = header.payloadRange.upperBound
    let availableContent = fullHeader.contentRange.upperBound - fullHeader.contentRange.lowerBound
    let minimumContentLength: Int64 = fullHeader.version == 1 ? 92 : 80
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
    let creationTime: UInt64
    let modificationTime: UInt64
    let trackID: UInt32
    let duration: UInt64
    let durationIs64Bit: Bool

    if fullHeader.version == 1 {
      guard let creation = try readUInt64(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "creation_time",
          value: String(creation),
          description: "Track creation timestamp",
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
    } else {
      guard let creation = try readUInt32(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
          name: "creation_time",
          value: String(creation),
          description: "Track creation timestamp",
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
    }

    guard let parsedTrackID = try readUInt32(reader, at: cursor, end: end) else { return nil }
    fields.append(
      ParsedBoxPayload.Field(
        name: "track_id",
        value: String(parsedTrackID),
        description: "Unique track identifier",
        byteRange: cursor..<(cursor + 4)
      ))
    trackID = parsedTrackID
    cursor += 4

    cursor += 4  // reserved

    if fullHeader.version == 1 {
      guard let durationValue = try readUInt64(reader, at: cursor, end: end) else { return nil }
      fields.append(
        ParsedBoxPayload.Field(
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
      fields.append(
        ParsedBoxPayload.Field(
          name: "duration",
          value: String(durationValue),
          description: "Track duration",
          byteRange: cursor..<(cursor + 4)
        ))
      duration = UInt64(durationValue)
      durationIs64Bit = false
      cursor += 4
    }

    cursor += 8  // reserved

    guard let layerValue = try readInt16(reader, at: cursor, end: end) else { return nil }
    fields.append(
      ParsedBoxPayload.Field(
        name: "layer",
        value: String(layerValue),
        description: "Track layer",
        byteRange: cursor..<(cursor + 2)
      ))
    cursor += 2

    guard let alternateGroupValue = try readInt16(reader, at: cursor, end: end) else { return nil }
    fields.append(
      ParsedBoxPayload.Field(
        name: "alternate_group",
        value: String(alternateGroupValue),
        description: "Alternate group",
        byteRange: cursor..<(cursor + 2)
      ))
    cursor += 2

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

    guard cursor + 2 <= end else { return nil }
    cursor += 2  // reserved

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

    guard matrixValues.count == 9 else { return nil }

    guard let widthRaw = try readUInt32(reader, at: cursor, end: end) else { return nil }
    let widthValue = Double(widthRaw) / 65536.0
    fields.append(
      ParsedBoxPayload.Field(
        name: "width",
        value: formatFixedPoint(widthRaw, integerBits: 16),
        description: "Track width",
        byteRange: cursor..<(cursor + 4)
      ))
    cursor += 4

    guard let heightRaw = try readUInt32(reader, at: cursor, end: end) else { return nil }
    let heightValue = Double(heightRaw) / 65536.0
    fields.append(
      ParsedBoxPayload.Field(
        name: "height",
        value: formatFixedPoint(heightRaw, integerBits: 16),
        description: "Track height",
        byteRange: cursor..<(cursor + 4)
      ))

    let isEnabled = (fullHeader.flags & 0x000001) != 0
    let isInMovie = (fullHeader.flags & 0x000002) != 0
    let isInPreview = (fullHeader.flags & 0x000004) != 0
    fields.append(
      ParsedBoxPayload.Field(
        name: "is_enabled",
        value: isEnabled ? "true" : "false",
        description: "Track enabled flag",
        byteRange: nil
      ))
    fields.append(
      ParsedBoxPayload.Field(
        name: "is_in_movie",
        value: isInMovie ? "true" : "false",
        description: "Track participates in movie presentation",
        byteRange: nil
      ))
    fields.append(
      ParsedBoxPayload.Field(
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
}
