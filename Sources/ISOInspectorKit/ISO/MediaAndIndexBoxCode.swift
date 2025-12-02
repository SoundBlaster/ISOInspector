import Foundation

/// Enumerates frequently used non-container structural boxes that influence ordering
/// and streaming heuristics in ISO Base Media File Format files.
public enum MediaAndIndexBoxCode: String, CaseIterable, Codable, Hashable, Sendable {
    /// `mdat` — Media data box containing raw encoded media payloads.
    case mediaData = "mdat"
    /// `sidx` — Segment index box signalling streaming segment boundaries.
    case segmentIndex = "sidx"
    /// `styp` — Segment type box describing segment compatibility for streaming.
    case segmentType = "styp"

    /// Convenience set of all known raw values for constant-time lookups.
    public static let rawValueSet: Set<String> = Set(allCases.map(\.rawValue))

    /// Convenience set of enum values for callers that prefer typed membership checks.
    public static let allCasesSet: Set<MediaAndIndexBoxCode> = Set(allCases)

    /// Set of enum values that represent streaming indicators.
    public static let streamingIndicators: Set<MediaAndIndexBoxCode> = [
        .segmentIndex, .segmentType,
    ]

    /// Set of enum values that represent media payload containers.
    public static let mediaPayloads: Set<MediaAndIndexBoxCode> = [.mediaData]

    /// Lazily cached set of raw strings for streaming indicator checks.
    private static let streamingIndicatorRawValues: Set<String> = Set(
        streamingIndicators.map(\.rawValue))

    /// Lazily cached set of raw strings for media payload checks.
    private static let mediaPayloadRawValues: Set<String> = Set(mediaPayloads.map(\.rawValue))

    /// The four-character code representation.
    public var fourCharCode: FourCharCode {
        guard let code = try? FourCharCode(rawValue) else {
            preconditionFailure("Invalid media/index raw value: \(rawValue)")
        }
        return code
    }

    /// Attempts to create the enum from a strongly typed `FourCharCode`.
    /// - Parameter fourCharCode: The code to convert.
    public init?(fourCharCode: FourCharCode) { self.init(rawValue: fourCharCode.rawValue) }

    /// Attempts to create the enum from a parsed box header.
    /// - Parameter boxHeader: Header whose type should be mapped to the enum.
    public init?(boxHeader: BoxHeader) { self.init(fourCharCode: boxHeader.type) }

    /// Determines whether the provided value represents a known media payload box.
    /// - Parameter value: The enum case to evaluate.
    public static func isMediaPayload(_ value: MediaAndIndexBoxCode) -> Bool {
        mediaPayloads.contains(value)
    }

    /// Determines whether the provided four-character code maps to a known media payload box.
    /// - Parameter value: The four-character code to evaluate.
    public static func isMediaPayload(_ value: FourCharCode) -> Bool {
        mediaPayloadRawValues.contains(value.rawValue)
    }

    /// Determines whether the provided raw string maps to a known media payload box.
    /// - Parameter value: The four-character string to evaluate.
    public static func isMediaPayload(_ value: String) -> Bool {
        mediaPayloadRawValues.contains(value)
    }

    /// Determines whether the provided header type maps to a known media payload box.
    /// - Parameter header: The box header to evaluate.
    public static func isMediaPayload(_ header: BoxHeader) -> Bool { isMediaPayload(header.type) }

    /// Determines whether the provided value represents a known streaming indicator box.
    /// - Parameter value: The enum case to evaluate.
    public static func isStreamingIndicator(_ value: MediaAndIndexBoxCode) -> Bool {
        streamingIndicators.contains(value)
    }

    /// Determines whether the provided four-character code maps to a known streaming indicator box.
    /// - Parameter value: The four-character code to evaluate.
    public static func isStreamingIndicator(_ value: FourCharCode) -> Bool {
        streamingIndicatorRawValues.contains(value.rawValue)
    }

    /// Determines whether the provided raw string maps to a known streaming indicator box.
    /// - Parameter value: The four-character string to evaluate.
    public static func isStreamingIndicator(_ value: String) -> Bool {
        streamingIndicatorRawValues.contains(value)
    }

    /// Determines whether the provided header represents a known streaming indicator box.
    /// - Parameter header: The box header to evaluate.
    public static func isStreamingIndicator(_ header: BoxHeader) -> Bool {
        isStreamingIndicator(header.type)
    }
}
