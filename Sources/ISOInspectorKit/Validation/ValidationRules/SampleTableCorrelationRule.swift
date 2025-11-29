import Foundation

/// Validates correlation between sample table boxes in ISO/IEC 14496-12 tracks.
///
/// Sample tables contain multiple interdependent boxes that must be internally consistent:
/// - **Sample-to-Chunk (stsc)**: Maps samples to chunks
/// - **Chunk Offset (stco/co64)**: Defines chunk locations
/// - **Sample Size (stsz/stz2)**: Declares total sample count
/// - **Time-to-Sample (stts)**: Decoding time deltas
/// - **Composition Offset (ctts)**: Composition time deltas
///
/// This rule verifies:
/// - Sample counts match across all tables
/// - Chunk coverage is complete and non-overlapping
/// - Chunk offsets are monotonically increasing
/// - No references to non-existent chunks
///
/// ## Rule ID
/// - **VR-015**: Sample table correlation
///
/// ## Severity
/// - **Error**: Inconsistent sample counts, invalid chunk references, or missing coverage
///
/// ## Example Violations
/// - Sample size table declares 100 samples but time-to-sample sums to 95 samples
/// - Sample-to-chunk references chunk 50 but chunk offset table only defines 40 chunks
/// - Chunk offset table has non-monotonic offsets (chunk 5 at offset 1000, chunk 6 at offset 900)
// swiftlint:disable type_body_length
final class SampleTableCorrelationRule: BoxValidationRule, @unchecked Sendable {
  private struct SampleToChunkState {
    let identifier: String
    let box: ParsedBoxPayload.SampleToChunkBox
  }

  private struct SampleSizeState {
    let identifier: String
    let sampleCount: UInt32
  }

  private struct ChunkOffsetState {
    let identifier: String
    let entries: [ParsedBoxPayload.ChunkOffsetBox.Entry]
  }

  private struct TimeToSampleState {
    let identifier: String
    let totalSamples: UInt64
  }

  private struct CompositionOffsetState {
    let identifier: String
    let totalSamples: UInt64
  }

  private struct TrackContext {
    var trackHeader: ParsedBoxPayload.TrackHeaderBox?
    var sampleToChunk: SampleToChunkState?
    var sampleSize: SampleSizeState?
    var chunkOffsets: ChunkOffsetState?
    var timeToSample: TimeToSampleState?
    var compositionOffset: CompositionOffsetState?
  }

  private var trackStack: [TrackContext] = []

  func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
    switch event.kind {
    case .willStartBox(let header, let depth):
      trimStack(to: depth)

      if header.type == BoxType.track {
        trackStack.append(TrackContext())
        return []
      }

      guard let trackIndex = trackStack.indices.last else { return [] }

      switch header.type {
      case BoxType.trackHeader:
        if let detail = event.payload?.trackHeader {
          trackStack[trackIndex].trackHeader = detail
        }
        return []
      case BoxType.sampleToChunk:
        guard let box = event.payload?.sampleToChunk else { return [] }
        trackStack[trackIndex].sampleToChunk = SampleToChunkState(
          identifier: header.identifierString,
          box: box
        )
        return evaluateTrack(for: trackIndex, triggeredKind: .sampleToChunk)
      case BoxType.sampleSize:
        guard let box = event.payload?.sampleSize else { return [] }
        trackStack[trackIndex].sampleSize = SampleSizeState(
          identifier: header.identifierString,
          sampleCount: box.sampleCount
        )
        return evaluateTrack(for: trackIndex, triggeredKind: .sampleSize)
      case BoxType.compactSampleSize:
        guard let box = event.payload?.compactSampleSize else { return [] }
        trackStack[trackIndex].sampleSize = SampleSizeState(
          identifier: header.identifierString,
          sampleCount: box.sampleCount
        )
        return evaluateTrack(for: trackIndex, triggeredKind: .sampleSize)
      case BoxType.chunkOffset32, BoxType.chunkOffset64:
        guard let box = event.payload?.chunkOffset else { return [] }
        trackStack[trackIndex].chunkOffsets = ChunkOffsetState(
          identifier: header.identifierString,
          entries: box.entries
        )
        var issues = chunkOffsetOrderingIssues(
          entries: box.entries,
          trackIndex: trackIndex,
          header: header
        )
        issues.append(contentsOf: evaluateTrack(for: trackIndex, triggeredKind: .chunkOffsets))
        return issues
      case BoxType.decodingTimeToSample:
        guard let box = event.payload?.decodingTimeToSample else { return [] }
        trackStack[trackIndex].timeToSample = TimeToSampleState(
          identifier: header.identifierString,
          totalSamples: totalSampleCount(box.entries.map { $0.sampleCount })
        )
        return evaluateTrack(for: trackIndex, triggeredKind: .timeToSample)
      case BoxType.compositionOffset:
        guard let box = event.payload?.compositionOffset else { return [] }
        trackStack[trackIndex].compositionOffset = CompositionOffsetState(
          identifier: header.identifierString,
          totalSamples: totalSampleCount(box.entries.map { $0.sampleCount })
        )
        return evaluateTrack(for: trackIndex, triggeredKind: .compositionOffset)
      default:
        return []
      }
    case .didFinishBox(let header, let depth):
      trimStack(to: depth)
      if header.type == BoxType.track, !trackStack.isEmpty {
        trackStack.removeLast()
      }
      return []
    }
  }

  private func trimStack(to depth: Int) {
    if trackStack.count > depth {
      trackStack.removeLast(trackStack.count - depth)
    }
  }

  private func evaluateTrack(for trackIndex: Int, triggeredKind: SampleTableKind)
    -> [ValidationIssue]
  {
    var issues: [ValidationIssue] = []
    switch triggeredKind {
    case .chunkOffsets, .sampleToChunk, .sampleSize:
      issues.append(contentsOf: chunkCorrelationIssues(for: trackIndex))
    case .timeToSample, .compositionOffset:
      break
    }
    issues.append(
      contentsOf: sampleCountConsistencyIssues(for: trackIndex, triggeredKind: triggeredKind))
    return issues
  }

  // swiftlint:disable:next function_body_length
  private func chunkCorrelationIssues(for trackIndex: Int) -> [ValidationIssue] {
    let context = trackStack[trackIndex]
    guard let sampleToChunk = context.sampleToChunk,
      let sampleSize = context.sampleSize,
      let chunkOffsets = context.chunkOffsets
    else {
      return []
    }

    let chunkCount = chunkOffsets.entries.count
    let declaredSamples = UInt64(sampleSize.sampleCount)
    let trackLabel = trackDescription(for: context)
    var issues: [ValidationIssue] = []

    if chunkCount == 0 {
      if declaredSamples > 0 {
        issues.append(
          ValidationIssue(
            ruleID: "VR-015",
            message:
              "\(trackLabel) chunk offset table \(chunkOffsets.identifier) declares 0 chunks but sample size table \(sampleSize.identifier) declares \(declaredSamples) samples.",
            severity: .error
          ))
      }
      return issues
    }

    let entries = sampleToChunk.box.entries
    if entries.isEmpty {
      if declaredSamples > 0 {
        issues.append(
          ValidationIssue(
            ruleID: "VR-015",
            message:
              "\(trackLabel) sample-to-chunk table \(sampleToChunk.identifier) contains no entries but chunk offset table \(chunkOffsets.identifier) defines \(chunkCount) chunks.",
            severity: .error
          ))
      }
      return issues
    }

    var sortedEntries = entries
    sortedEntries.sort { $0.firstChunk < $1.firstChunk }

    var coverage = 0
    var totalSamples = UInt64(0)

    for (index, entry) in sortedEntries.enumerated() {
      let start = Int(entry.firstChunk)
      if start < 1 {
        issues.append(
          ValidationIssue(
            ruleID: "VR-015",
            message:
              "\(trackLabel) sample-to-chunk table \(sampleToChunk.identifier) has entry \(index + 1) with invalid first_chunk \(entry.firstChunk).",
            severity: .error
          ))
        continue
      }

      if start > chunkCount {
        issues.append(
          ValidationIssue(
            ruleID: "VR-015",
            message:
              "\(trackLabel) sample-to-chunk table \(sampleToChunk.identifier) references chunk \(entry.firstChunk) but chunk offset table \(chunkOffsets.identifier) only defines \(chunkCount) chunks.",
            severity: .error
          ))
        continue
      }

      if index + 1 < sortedEntries.count,
        sortedEntries[index + 1].firstChunk <= entry.firstChunk
      {
        issues.append(
          ValidationIssue(
            ruleID: "VR-015",
            message:
              "\(trackLabel) sample-to-chunk table \(sampleToChunk.identifier) has non-monotonic first_chunk values at entries \(index + 1) and \(index + 2).",
            severity: .error
          ))
      }

      let nextStart =
        index + 1 < sortedEntries.count
        ? Int(sortedEntries[index + 1].firstChunk)
        : chunkCount + 1
      let runEnd = min(nextStart, chunkCount + 1)

      if runEnd <= start {
        continue
      }

      let runLength = runEnd - start
      coverage += runLength
      totalSamples += UInt64(runLength) * UInt64(entry.samplesPerChunk)
    }

    if coverage < chunkCount {
      let missing = chunkCount - coverage
      issues.append(
        ValidationIssue(
          ruleID: "VR-015",
          message:
            "\(trackLabel) sample-to-chunk table \(sampleToChunk.identifier) only covers \(coverage) of \(chunkCount) chunks declared by \(chunkOffsets.identifier) (missing \(missing)).",
          severity: .error
        ))
    }

    if totalSamples != declaredSamples {
      issues.append(
        ValidationIssue(
          ruleID: "VR-015",
          message:
            "\(trackLabel) sample size table \(sampleSize.identifier) declares \(declaredSamples) samples but sample-to-chunk table \(sampleToChunk.identifier) expands to \(totalSamples) samples across \(chunkCount) chunks.",
          severity: .error
        ))
    }

    return issues
  }

  // swiftlint:disable:next function_body_length
  private func sampleCountConsistencyIssues(for trackIndex: Int, triggeredKind: SampleTableKind)
    -> [ValidationIssue]
  {
    let context = trackStack[trackIndex]
    let trackLabel = trackDescription(for: context)
    var issues: [ValidationIssue] = []

    if triggeredKind == .sampleSize || triggeredKind == .timeToSample,
      let sampleSize = context.sampleSize,
      let timeToSample = context.timeToSample
    {
      let declared = UInt64(sampleSize.sampleCount)
      if timeToSample.totalSamples != declared {
        issues.append(
          ValidationIssue(
            ruleID: "VR-015",
            message:
              "\(trackLabel) time-to-sample table \(timeToSample.identifier) sums to \(timeToSample.totalSamples) samples but sample size table \(sampleSize.identifier) declares \(declared) samples.",
            severity: .error
          ))
      }
    }

    if triggeredKind == .sampleSize || triggeredKind == .compositionOffset,
      let sampleSize = context.sampleSize,
      let composition = context.compositionOffset
    {
      let declared = UInt64(sampleSize.sampleCount)
      if composition.totalSamples != declared {
        issues.append(
          ValidationIssue(
            ruleID: "VR-015",
            message:
              "\(trackLabel) composition offset table \(composition.identifier) sums to \(composition.totalSamples) samples but sample size table \(sampleSize.identifier) declares \(declared) samples.",
            severity: .error
          ))
      }
    }

    if triggeredKind == .timeToSample || triggeredKind == .compositionOffset,
      let timeToSample = context.timeToSample,
      let composition = context.compositionOffset,
      timeToSample.totalSamples != composition.totalSamples
    {
      issues.append(
        ValidationIssue(
          ruleID: "VR-015",
          message:
            "\(trackLabel) time-to-sample table \(timeToSample.identifier) sums to \(timeToSample.totalSamples) samples but composition offset table \(composition.identifier) covers \(composition.totalSamples) samples.",
          severity: .error
        ))
    }

    return issues
  }

  private func totalSampleCount<S: Sequence>(_ counts: S) -> UInt64 where S.Element == UInt32 {
    counts.reduce(UInt64(0)) { total, value in
      let (next, overflow) = total.addingReportingOverflow(UInt64(value))
      return overflow ? UInt64.max : next
    }
  }

  private enum SampleTableKind {
    case sampleToChunk
    case sampleSize
    case chunkOffsets
    case timeToSample
    case compositionOffset
  }

  private func chunkOffsetOrderingIssues(
    entries: [ParsedBoxPayload.ChunkOffsetBox.Entry],
    trackIndex: Int,
    header: BoxHeader
  ) -> [ValidationIssue] {
    guard entries.count >= 2 else { return [] }
    let context = trackStack[trackIndex]
    let label = trackDescription(for: context)

    for index in entries.indices.dropFirst() {
      let previous = entries[index - 1]
      let current = entries[index]
      if current.offset <= previous.offset {
        let message =
          "\(label) chunk offset table \(header.identifierString) has non-monotonic offsets at entries \(previous.index) and \(current.index) (\(previous.offset) then \(current.offset))."
        return [ValidationIssue(ruleID: "VR-015", message: message, severity: .error)]
      }
    }

    return []
  }

  private func trackDescription(for context: TrackContext) -> String {
    if let trackID = context.trackHeader?.trackID {
      return "Track \(trackID)"
    }
    return "Track"
  }

  private enum BoxType {
    static let track = try! FourCharCode("trak")
    static let trackHeader = try! FourCharCode("tkhd")
    static let sampleToChunk = try! FourCharCode("stsc")
    static let sampleSize = try! FourCharCode("stsz")
    static let compactSampleSize = try! FourCharCode("stz2")
    static let chunkOffset32 = try! FourCharCode("stco")
    static let chunkOffset64 = try! FourCharCode("co64")
    static let decodingTimeToSample = try! FourCharCode("stts")
    static let compositionOffset = try! FourCharCode("ctts")
  }
}
