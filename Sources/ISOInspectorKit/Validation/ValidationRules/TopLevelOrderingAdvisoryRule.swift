import Foundation

/// Advisory rule for top-level box ordering in ISO/IEC 14496-12 files.
///
/// While the specification allows flexible ordering, certain patterns indicate
/// potential muxer issues or non-optimal packaging:
///
/// ## Pre-FileType Checks
/// - Reports unexpected boxes before ftyp (excluding free/skip/wide/uuid padding)
///
/// ## FileType-to-Movie Checks
/// - Reports unexpected boxes between ftyp and moov (excluding padding and streaming indicators)
/// - Reports moov appearing after media data when streaming indicators are present
///
/// ## Rule ID
/// - **E3**: Top-level ordering advisory
///
/// ## Severity
/// - **Warning**: Non-standard ordering detected
///
/// ## Example Violations
/// - Box "meta" appears before ftyp
/// - Box "udta" appears between ftyp and moov
/// - moov appears after mdat following streaming indicator moof
final class TopLevelOrderingAdvisoryRule: BoxValidationRule, @unchecked Sendable {
  private static let ruleID = "E3"
  private static let fileType = "ftyp"
  private static let movieType = FourCharContainerCode.moov.rawValue
  private static let paddingTypes: Set<String> = ["free", "skip", "wide"]
  private static let allowedPreFileTypeTypes: Set<String> = paddingTypes.union(["uuid"])
  private static let streamingIndicatorTypes: Set<String> = {
    var values = Set(MediaAndIndexBoxCode.streamingIndicators.map(\.rawValue))
    values.insert(FourCharContainerCode.moof.rawValue)
    return values
  }()
  private static let allowedBetweenTypes: Set<String> =
    allowedPreFileTypeTypes.union(streamingIndicatorTypes)

  private var hasSeenFileType = false
  private var hasSeenMovie = false
  private var typesBeforeFileType: [String] = []
  private var typesBetweenFileTypeAndMovie: [String] = []
  private var streamingIndicatorsBeforeMovie: Set<String> = []
  private var mediaPayloadTypesBeforeMovie: Set<String> = []
  private var emittedFileTypeAdvisory = false
  private var emittedMovieAdvisory = false

  // Single-state-machine handler for top-level ordering scenarios.
  // swiftlint:disable:next cyclomatic_complexity
  func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
    guard case .willStartBox(let header, let depth) = event.kind, depth == 0 else { return [] }
    let type = header.type.rawValue

    if hasSeenFileType, !hasSeenMovie, type != Self.movieType {
      if Self.streamingIndicatorTypes.contains(type) {
        streamingIndicatorsBeforeMovie.insert(type)
      }
      if MediaAndIndexBoxCode.isMediaPayload(type) {
        mediaPayloadTypesBeforeMovie.insert(type)
      }
    }

    if type == Self.fileType {
      if !hasSeenFileType {
        hasSeenFileType = true
        return fileTypeIssuesIfNeeded()
      }
      return []
    }

    if !hasSeenFileType {
      typesBeforeFileType.append(type)
      return []
    }

    if hasSeenMovie {
      return []
    }

    if type == Self.movieType {
      hasSeenMovie = true
      return movieIssuesIfNeeded()
    }

    typesBetweenFileTypeAndMovie.append(type)
    return []
  }

  private func fileTypeIssuesIfNeeded() -> [ValidationIssue] {
    guard !emittedFileTypeAdvisory else { return [] }
    let unexpected = Set(typesBeforeFileType.filter { !Self.allowedPreFileTypeTypes.contains($0) })
    guard !unexpected.isEmpty else { return [] }
    emittedFileTypeAdvisory = true
    let summary = Self.describe(unexpected)
    let message =
      "Top-level box \(summary) appeared before the file type box (ftyp); verify muxer packaging order."
    return [ValidationIssue(ruleID: Self.ruleID, message: message, severity: .warning)]
  }

  private func movieIssuesIfNeeded() -> [ValidationIssue] {
    guard !emittedMovieAdvisory else { return [] }

    let unexpected = Set(
      typesBetweenFileTypeAndMovie.filter { type in
        !Self.allowedBetweenTypes.contains(type) && !MediaAndIndexBoxCode.isMediaPayload(type)
      })
    if !unexpected.isEmpty {
      emittedMovieAdvisory = true
      let summary = Self.describe(unexpected)
      let message =
        "Top-level box \(summary) appeared between file type (ftyp) and movie (moov) boxes; review packaging workflow."
      return [ValidationIssue(ruleID: Self.ruleID, message: message, severity: .warning)]
    }

    if !mediaPayloadTypesBeforeMovie.isEmpty, !streamingIndicatorsBeforeMovie.isEmpty {
      emittedMovieAdvisory = true
      let mediaSummary = Self.describe(mediaPayloadTypesBeforeMovie)
      let indicatorSummary = Self.describe(streamingIndicatorsBeforeMovie)
      let message =
        "Movie box (moov) arrived after media payload \(mediaSummary) following streaming indicators \(indicatorSummary); confirm initialization metadata remains accessible."
      return [ValidationIssue(ruleID: Self.ruleID, message: message, severity: .warning)]
    }

    return []
  }

  private static func describe(_ codes: Set<String>) -> String {
    describe(Array(codes))
  }

  private static func describe(_ codes: [String]) -> String {
    let unique = Array(Set(codes)).sorted()
    guard let first = unique.first else { return "" }
    if unique.count == 1 {
      return "\"\(first)\""
    }
    if unique.count == 2 {
      return "\"\(first)\" and \"\(unique[1])\""
    }
    return "\"\(first)\" and \(unique.count - 1) others"
  }
}
