import Foundation

/// Utility namespace that classifies parsed boxes into ``BoxCategory`` values and exposes
/// streaming indicator checks shared across the app and CLI.
public enum BoxClassifier {
  /// Known four-character codes that should always be treated as metadata containers.
  private static let metadataRawValues: Set<String> = [
    "meta",
    "ilst",
    "udta",
    "mdta",
    "cprt",
  ]

  public static func category(for header: BoxHeader, metadata: BoxDescriptor?) -> BoxCategory {
    if MediaAndIndexBoxCode.isStreamingIndicator(header) {
      return .index
    }
    if MediaAndIndexBoxCode.isMediaPayload(header) {
      return .media
    }
    if isMetadata(header: header, descriptor: metadata) {
      return .metadata
    }
    if FourCharContainerCode.isContainer(header) {
      return .container
    }
    return .other
  }

  public static func isStreamingIndicator(header: BoxHeader) -> Bool {
    MediaAndIndexBoxCode.isStreamingIndicator(header)
  }

  private static func isMetadata(header: BoxHeader, descriptor: BoxDescriptor?) -> Bool {
    if metadataRawValues.contains(header.type.rawValue) {
      return true
    }
    if let descriptor {
      // Prefer descriptor-provided naming hints over summary parsing so we can
      // broaden coverage without brittle string heuristics.
      let name = descriptor.name.lowercased()
      if name.contains("metadata") || name.contains("meta-data") {
        return true
      }
    }
    return false
  }
}
