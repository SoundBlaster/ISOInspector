import Foundation

/// Validates that movie data (mdat) appears after movie metadata (moov) in non-streaming files.
///
/// For progressive download files (non-fragmented, non-streaming), the movie box (moov)
/// should appear before media data (mdat) to enable:
/// - Immediate playback without seeking to end of file
/// - Progressive download support
/// - Efficient streaming over HTTP
///
/// This rule is skipped for fragmented files or files with streaming indicators
/// (moof, mvex, sidx, ssix, prft) where mdat-before-moov is expected.
///
/// ## Rule ID
/// - **VR-005**: Movie data ordering
///
/// ## Severity
/// - **Warning**: mdat before moov in non-streaming file
///
/// ## Example Violations
/// - File structure: ftyp, mdat, moov (should be ftyp, moov, mdat)
/// - Progressive download file with metadata at end
final class MovieDataOrderingRule: BoxValidationRule, @unchecked Sendable {
  private var hasSeenMovieBox = false
  private var hasStreamingIndicator = false

  func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
    guard case .willStartBox(let header, _) = event.kind else { return [] }

    let type = header.type.rawValue

    if Self.streamingIndicatorTypes.contains(type) {
      hasStreamingIndicator = true
    }

    if type == FourCharContainerCode.moov.rawValue {
      hasSeenMovieBox = true
      return []
    }

    guard MediaAndIndexBoxCode.isMediaPayload(type) else { return [] }
    guard !hasSeenMovieBox, !hasStreamingIndicator else { return [] }

    let message =
      "Movie data box (mdat) encountered before movie box (moov); ensure initialization metadata precedes media."
    return [ValidationIssue(ruleID: "VR-005", message: message, severity: .warning)]
  }

  private static let streamingIndicatorTypes: Set<String> = {
    var values: Set<String> = [
      FourCharContainerCode.moof.rawValue,
      FourCharContainerCode.mvex.rawValue,
      "ssix",
      "prft",
    ]
    values.formUnion(MediaAndIndexBoxCode.streamingIndicators.map(\.rawValue))
    return values
  }()
}
