import XCTest

@testable import ISOInspectorCLI
@testable import ISOInspectorKit

final class EventConsoleFormatterTests: XCTestCase {
  func testFormatterIncludesMetadataDetails() throws {
    let header = try makeHeader(type: "ftyp", size: 24)
    let descriptor = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 0),
      offset: 0,
      metadata: descriptor
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains(descriptor.name))
    XCTAssertTrue(output.contains(descriptor.summary))
  }

  func testFormatterIncludesValidationIssues() throws {
    let header = try makeHeader(type: "tkhd", size: 40)
    let descriptor = BoxCatalog.shared.descriptor(for: header)
    let issue = ValidationIssue(
      ruleID: "VR-003",
      message: "Expected version 0 but found 1",
      severity: .warning
    )
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 1),
      offset: 8,
      metadata: descriptor,
      validationIssues: [issue]
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("VR-003"))
    XCTAssertTrue(output.contains("warning"))
    XCTAssertTrue(output.contains("Expected version 0 but found 1"))
  }

  func testFormatterIncludesMovieFragmentSequenceNumber() throws {
    let header = try makeHeader(type: "mfhd", size: 16)
    let payload = ParsedBoxPayload(
      fields: [
        ParsedBoxPayload.Field(
          name: "version",
          value: "0",
          description: "Structure version",
          byteRange: 8..<9
        ),
        ParsedBoxPayload.Field(
          name: "flags",
          value: "0x000000",
          description: "Bit flags",
          byteRange: 9..<12
        ),
        ParsedBoxPayload.Field(
          name: "sequence_number",
          value: "7",
          description: "Fragment sequence number",
          byteRange: 12..<16
        ),
      ],
      detail: .movieFragmentHeader(
        ParsedBoxPayload.MovieFragmentHeaderBox(
          version: 0,
          flags: 0,
          sequenceNumber: 7
        )
      )
    )
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 0),
      offset: 0,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("sequence=7"))
  }

  func testFormatterIncludesTrackFragmentHeaderTrackID() throws {
    let header = try makeHeader(type: "tfhd", size: 20)
    let payload = ParsedBoxPayload(
      fields: [
        ParsedBoxPayload.Field(
          name: "track_id",
          value: "42",
          description: "Track identifier",
          byteRange: 12..<16
        )
      ],
      detail: .trackFragmentHeader(
        ParsedBoxPayload.TrackFragmentHeaderBox(
          version: 0,
          flags: 0,
          trackID: 42,
          baseDataOffset: nil,
          sampleDescriptionIndex: nil,
          defaultSampleDuration: nil,
          defaultSampleSize: nil,
          defaultSampleFlags: nil,
          durationIsEmpty: false,
          defaultBaseIsMoof: false
        )
      )
    )
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 0),
      offset: 0,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("track=42"))
  }

  func testFormatterIncludesTrackFragmentDecodeTime() throws {
    let header = try makeHeader(type: "tfdt", size: 20)
    let payload = ParsedBoxPayload(
      detail: .trackFragmentDecodeTime(
        ParsedBoxPayload.TrackFragmentDecodeTimeBox(
          version: 1,
          flags: 0,
          baseMediaDecodeTime: 9000,
          baseMediaDecodeTimeIs64Bit: true
        )
      )
    )
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 0),
      offset: 0,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("base_decode_time=9000"))
  }

  func testFormatterIncludesTrackRunSummary() throws {
    let header = try makeHeader(type: "trun", size: 24)
    let run = ParsedBoxPayload.TrackRunBox(
      version: 0,
      flags: 0x000001,
      sampleCount: 3,
      dataOffset: 256,
      firstSampleFlags: nil,
      entries: [],
      totalSampleDuration: 180,
      totalSampleSize: 1500,
      startDecodeTime: 1000,
      endDecodeTime: 1180,
      startPresentationTime: 1000,
      endPresentationTime: 1180,
      startDataOffset: 2048,
      endDataOffset: 2048 + 1500,
      trackID: 7,
      sampleDescriptionIndex: 2,
      runIndex: 0,
      firstSampleGlobalIndex: 1
    )
    let payload = ParsedBoxPayload(detail: .trackRun(run))
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 0),
      offset: 0,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("track=7"))
    XCTAssertTrue(output.contains("run=0"))
    XCTAssertTrue(output.contains("samples=3"))
    XCTAssertTrue(output.contains("first_sample=1"))
    XCTAssertTrue(output.contains("duration=180"))
    XCTAssertTrue(output.contains("size=1500"))
    XCTAssertTrue(output.contains("data_offset=256"))
    XCTAssertTrue(output.contains("data_range=2048-3548"))
    XCTAssertTrue(output.contains("decode=1000-1180"))
    XCTAssertTrue(output.contains("presentation=1000-1180"))
  }

  func testFormatterSummarizesTrackFragmentRandomAccess() throws {
    let header = try makeHeader(type: "tfra", size: 32)
    let entry = ParsedBoxPayload.TrackFragmentRandomAccessBox.Entry(
      index: 1,
      time: 12_000,
      moofOffset: 0,
      trafNumber: 1,
      trunNumber: 1,
      sampleNumber: 2,
      fragmentSequenceNumber: 9,
      trackID: 1,
      sampleDescriptionIndex: 1,
      runIndex: 0,
      firstSampleGlobalIndex: 1,
      resolvedDecodeTime: 12_000,
      resolvedPresentationTime: 12_000,
      resolvedDataOffset: 5_360,
      resolvedSampleSize: 1_500,
      resolvedSampleFlags: nil
    )
    let box = ParsedBoxPayload.TrackFragmentRandomAccessBox(
      version: 1,
      flags: 0,
      trackID: 1,
      trafNumberLength: 4,
      trunNumberLength: 4,
      sampleNumberLength: 4,
      entryCount: 1,
      entries: [entry]
    )
    let payload = ParsedBoxPayload(detail: .trackFragmentRandomAccess(box))
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 0),
      offset: 0,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("track=1"))
    XCTAssertTrue(output.contains("entries=1"))
    XCTAssertTrue(output.contains("fragment=9"))
    XCTAssertTrue(output.contains("sample=traf1:trun1:2"))
    XCTAssertTrue(output.contains("decode=12000"))
    XCTAssertTrue(output.contains("offset=5360"))
  }

  func testFormatterSummarizesMovieFragmentRandomAccess() throws {
    let header = try makeHeader(type: "mfra", size: 24)
    let trackSummary = ParsedBoxPayload.MovieFragmentRandomAccessBox.TrackSummary(
      trackID: 1,
      entryCount: 1,
      earliestTime: 12_000,
      latestTime: 12_000,
      referencedFragmentSequenceNumbers: [9]
    )
    let box = ParsedBoxPayload.MovieFragmentRandomAccessBox(
      tracks: [trackSummary],
      totalEntryCount: 1,
      offset: ParsedBoxPayload.MovieFragmentRandomAccessOffsetBox(mfraSize: 128)
    )
    let payload = ParsedBoxPayload(detail: .movieFragmentRandomAccess(box))
    let event = ParseEvent(
      kind: .didFinishBox(header: header, depth: 0),
      offset: 0,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("tracks=1"))
    XCTAssertTrue(output.contains("total_entries=1"))
    XCTAssertTrue(output.contains("fragments=[9]"))
    XCTAssertTrue(output.contains("mfra_size=128"))
  }

  func testFormatterHighlightsRunWithNegativeDataOffset() throws {
    let header = try makeHeader(type: "trun", size: 24)
    let run = ParsedBoxPayload.TrackRunBox(
      version: 0,
      flags: 0x000200,
      sampleCount: 1,
      dataOffset: -64,
      firstSampleFlags: nil,
      entries: [],
      totalSampleDuration: 240,
      totalSampleSize: 480,
      startDecodeTime: nil,
      endDecodeTime: nil,
      startPresentationTime: nil,
      endPresentationTime: nil,
      startDataOffset: nil,
      endDataOffset: nil,
      trackID: 2,
      sampleDescriptionIndex: 1,
      runIndex: 1,
      firstSampleGlobalIndex: 5
    )
    let payload = ParsedBoxPayload(detail: .trackRun(run))
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 0),
      offset: 0,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("track=2"))
    XCTAssertTrue(output.contains("run=1"))
    XCTAssertTrue(output.contains("data_offset=-64"))
    XCTAssertTrue(output.contains("data_range=unresolved"))
    XCTAssertTrue(output.contains("decode=unresolved"))
  }

  func testFormatterIncludesTrackFragmentSummary() throws {
    let header = try makeHeader(type: "traf", size: 40)
    let fragment = ParsedBoxPayload.TrackFragmentBox(
      trackID: 9,
      sampleDescriptionIndex: 5,
      baseDataOffset: 4096,
      defaultSampleDuration: 100,
      defaultSampleSize: 512,
      defaultSampleFlags: 0x0102_0304,
      durationIsEmpty: false,
      defaultBaseIsMoof: true,
      baseDecodeTime: 1200,
      baseDecodeTimeIs64Bit: false,
      runs: [],
      totalSampleCount: 4,
      totalSampleSize: 2048,
      totalSampleDuration: 400,
      earliestPresentationTime: 1000,
      latestPresentationTime: 1600,
      firstDecodeTime: 1200,
      lastDecodeTime: 1600
    )
    let payload = ParsedBoxPayload(detail: .trackFragment(fragment))
    let event = ParseEvent(
      kind: .didFinishBox(header: header, depth: 0),
      offset: header.endOffset,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("track=9"))
    XCTAssertTrue(output.contains("runs=0"))
    XCTAssertTrue(output.contains("samples=4"))
    XCTAssertTrue(output.contains("duration=400"))
    XCTAssertTrue(output.contains("size=2048"))
    XCTAssertTrue(output.contains("base_decode=1200"))
    XCTAssertTrue(output.contains("decode=1200-1600"))
    XCTAssertTrue(output.contains("presentation=1000-1600"))
  }

  func testFormatterSummarizesSampleEncryptionMetadata() throws {
    let header = try makeHeader(type: "senc", size: 40)
    let detail = ParsedBoxPayload.SampleEncryptionBox(
      version: 0,
      flags: 0x000003,
      sampleCount: 2,
      algorithmIdentifier: 0x010203,
      perSampleIVSize: 8,
      keyIdentifierRange: 24..<40,
      sampleInfoRange: 40..<48,
      sampleInfoByteLength: 8,
      constantIVRange: nil,
      constantIVByteLength: nil
    )
    let payload = ParsedBoxPayload(detail: .sampleEncryption(detail))
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 0),
      offset: 0,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("encryption"))
    XCTAssertTrue(output.contains("samples=2"))
    XCTAssertTrue(output.contains("iv_size=8"))
    XCTAssertTrue(output.contains("algorithm=0x010203"))
    XCTAssertTrue(output.contains("sample_bytes=8"))
    XCTAssertTrue(output.contains("key_range=24-40"))
  }

  func testFormatterSummarizesSampleAuxInfoOffsets() throws {
    let header = try makeHeader(type: "saio", size: 36)
    let detail = ParsedBoxPayload.SampleAuxInfoOffsetsBox(
      version: 0,
      flags: 0x000001,
      entryCount: 3,
      auxInfoType: try FourCharCode("cenc"),
      auxInfoTypeParameter: 2,
      entrySize: .eightBytes,
      entriesRange: 80..<104,
      entriesByteLength: 24
    )
    let payload = ParsedBoxPayload(detail: .sampleAuxInfoOffsets(detail))
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 0),
      offset: 0,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("aux_offsets"))
    XCTAssertTrue(output.contains("entries=3"))
    XCTAssertTrue(output.contains("bytes_per_entry=8"))
    XCTAssertTrue(output.contains("type=cenc"))
    XCTAssertTrue(output.contains("range=80-104"))
  }

  func testFormatterSummarizesSampleAuxInfoSizes() throws {
    let header = try makeHeader(type: "saiz", size: 32)
    let detail = ParsedBoxPayload.SampleAuxInfoSizesBox(
      version: 0,
      flags: 0x000001,
      defaultSampleInfoSize: 0,
      entryCount: 3,
      auxInfoType: try FourCharCode("cenc"),
      auxInfoTypeParameter: 2,
      variableEntriesRange: 120..<123,
      variableEntriesByteLength: 3
    )
    let payload = ParsedBoxPayload(detail: .sampleAuxInfoSizes(detail))
    let event = ParseEvent(
      kind: .willStartBox(header: header, depth: 0),
      offset: 0,
      payload: payload
    )

    let formatter = EventConsoleFormatter()
    let output = formatter.format(event)

    XCTAssertTrue(output.contains("aux_sizes"))
    XCTAssertTrue(output.contains("entry_count=3"))
    XCTAssertTrue(output.contains("default=0"))
    XCTAssertTrue(output.contains("variable_bytes=3"))
    XCTAssertTrue(output.contains("range=120-123"))
  }

  private func makeHeader(type: String, size: Int64) throws -> BoxHeader {
    let fourCC = try FourCharCode(type)
    let range = Int64(0)..<size
    let payloadRange = Int64(8)..<size
    return BoxHeader(
      type: fourCC,
      totalSize: size,
      headerSize: 8,
      payloadRange: payloadRange,
      range: range,
      uuid: nil
    )
  }
}
