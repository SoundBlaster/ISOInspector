import Foundation

extension BoxParserRegistry.DefaultParsers {
  static func sampleEntryHeaderLength(for format: FourCharCode) -> Int64? {
    if visualSampleEntryTypes.contains(format) {
      return 70
    }
    if audioSampleEntryTypes.contains(format) {
      return 20
    }
    return nil
  }

  static func parseVisualSampleEntry(
    reader: RandomAccessReader,
    contentStart: Int64,
    entryEnd: Int64,
    index: Int
  ) -> [ParsedBoxPayload.Field] {
    var fields: [ParsedBoxPayload.Field] = []
    let widthOffset = contentStart + 16
    let heightOffset = widthOffset + 2

    if widthOffset + 2 <= entryEnd,
      let width = (try? readUInt16(reader, at: widthOffset, end: entryEnd)) ?? nil
    {
      fields.append(
        ParsedBoxPayload.Field(
          name: "entries[\(index)].width",
          value: String(width),
          description: "Visual sample width",
          byteRange: widthOffset..<(widthOffset + 2)
        ))
    }

    if heightOffset + 2 <= entryEnd,
      let height = (try? readUInt16(reader, at: heightOffset, end: entryEnd)) ?? nil
    {
      fields.append(
        ParsedBoxPayload.Field(
          name: "entries[\(index)].height",
          value: String(height),
          description: "Visual sample height",
          byteRange: heightOffset..<(heightOffset + 2)
        ))
    }

    return fields
  }

  static func parseAudioSampleEntry(
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
      let channelCount = (try? readUInt16(reader, at: channelCountOffset, end: entryEnd)) ?? nil
    {
      fields.append(
        ParsedBoxPayload.Field(
          name: "entries[\(index)].channelcount",
          value: String(channelCount),
          description: "Audio channel count",
          byteRange: channelCountOffset..<(channelCountOffset + 2)
        ))
    }

    if sampleSizeOffset + 2 <= entryEnd,
      let sampleSize = (try? readUInt16(reader, at: sampleSizeOffset, end: entryEnd)) ?? nil
    {
      fields.append(
        ParsedBoxPayload.Field(
          name: "entries[\(index)].samplesize",
          value: String(sampleSize),
          description: "Audio sample size",
          byteRange: sampleSizeOffset..<(sampleSizeOffset + 2)
        ))
    }

    if sampleRateOffset + 4 <= entryEnd,
      let rawRate = try? reader.readUInt32(at: sampleRateOffset)
    {
      let integerRate = rawRate >> 16
      fields.append(
        ParsedBoxPayload.Field(
          name: "entries[\(index)].samplerate",
          value: String(integerRate),
          description: "Audio sample rate",
          byteRange: sampleRateOffset..<(sampleRateOffset + 4)
        ))
    }

    return fields
  }

  struct NestedBox {
    let type: FourCharCode
    let range: Range<Int64>
    let payloadRange: Range<Int64>
  }

  static func parseChildBoxes(
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
      guard let type = (try? readFourCC(reader, at: cursor + 4, end: entryEnd)) ?? nil else {
        break
      }

      var headerLength: Int64 = 8
      var boxLength = Int64(size)
      if size == 1 {
        headerLength = 16
        guard let largeSize = (try? readUInt64(reader, at: cursor + 8, end: entryEnd)) ?? nil else {
          break
        }
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
}
