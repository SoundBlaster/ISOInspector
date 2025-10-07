import Foundation

/// Strongly typed representation of the ISO Base Media File Format container boxes
/// that may contain child boxes. Centralising the codes minimises typos and keeps
/// parsing logic aligned with the specification.
public enum FourCharContainerCode: String, CaseIterable, Codable, Hashable, Sendable {
    /// `moov` — Movie box, the top-level container for movie metadata including tracks and timing information.
    case movie = "moov"
    /// `trak` — Track box, encapsulates metadata for an individual track within the movie box.
    case track = "trak"
    /// `mdia` — Media box, groups the components that describe the media data for a track.
    case media = "mdia"
    /// `minf` — Media information box, holds media-specific information required to decode a track.
    case mediaInformation = "minf"
    /// `dinf` — Data information box, contains information about the location of the media data.
    case dataInformation = "dinf"
    /// `stbl` — Sample table box, aggregates timing and chunk tables that describe media samples.
    case sampleTable = "stbl"
    /// `edts` — Edit box, wraps edit lists describing presentation edits applied to a track.
    case edit = "edts"
    /// `mvex` — Movie extends box, signals the presence of movie fragments for streaming.
    case movieExtends = "mvex"
    /// `moof` — Movie fragment box, container for fragment-level metadata and track fragments.
    case movieFragment = "moof"
    /// `traf` — Track fragment box, groups fragment metadata for a single track inside a movie fragment.
    case trackFragment = "traf"
    /// `mfra` — Movie fragment random access box, provides random access entries for movie fragments.
    case movieFragmentRandomAccess = "mfra"
    /// `tref` — Track reference box, lists references between tracks such as dependencies or relationships.
    case trackReference = "tref"
    /// `udta` — User data box, stores user-defined or application-specific metadata.
    case userData = "udta"
    /// `strk` — Subtrack box, container for sub-track definitions within user data.
    case subtrack = "strk"
    /// `strd` — Subtrack definition box, provides details about the subtrack entries.
    case subtrackDefinition = "strd"
    /// `sinf` — Protection scheme information box, wraps common encryption or protection descriptors.
    case protectionSchemeInformation = "sinf"
    /// `schi` — Scheme information box, carries scheme-specific protection details.
    case schemeInformation = "schi"
    /// `stsd` — Sample description box, contains codec descriptions and sample entry definitions.
    case sampleDescription = "stsd"
    /// `meta` — Metadata box, encloses structured metadata such as iTunes style tags.
    case metadata = "meta"
    /// `ilst` — iTunes metadata list box, holds key/value metadata entries inside the metadata box.
    case itunesMetadata = "ilst"

    /// Precomputed set of all container codes for constant-time membership checks.
    public static let rawValueSet: Set<String> = Set(allCases.map(\.rawValue))

    /// Convenience set of enum values for lookup scenarios that prefer enums over strings.
    public static let allCasesSet: Set<FourCharContainerCode> = Set(allCases)

    /// The four-character code as a strongly typed `FourCharCode` value.
    public var fourCharCode: FourCharCode {
        // Raw values are guaranteed to be valid four-character codes by construction.
        guard let code = try? FourCharCode(rawValue) else {
            preconditionFailure("Invalid container raw value: \(rawValue)")
        }
        return code
    }

    /// Creates an enum instance from a `FourCharCode` value.
    /// - Parameter fourCharCode: The code to convert.
    public init?(fourCharCode: FourCharCode) {
        self.init(rawValue: fourCharCode.rawValue)
    }

    /// Creates an enum instance from a parsed `BoxHeader`.
    /// - Parameter boxHeader: The header whose type should be mapped to the enum.
    public init?(boxHeader: BoxHeader) {
        self.init(fourCharCode: boxHeader.type)
    }

    /// Determines whether a `FourCharCode` represents a known container box.
    /// - Parameter value: The code to check.
    /// - Returns: `true` when the code is one of the known container types.
    public static func isContainer(_ value: FourCharCode) -> Bool {
        rawValueSet.contains(value.rawValue)
    }

    /// Determines whether a raw string represents a known container box.
    /// - Parameter value: Four-character string to inspect.
    /// - Returns: `true` when the string maps to a known container code.
    public static func isContainer(_ value: String) -> Bool {
        rawValueSet.contains(value)
    }

    /// Determines whether the provided `BoxHeader` represents a container box.
    /// - Parameter header: Parsed box header to evaluate.
    /// - Returns: `true` when the header's type is a known container.
    public static func isContainer(_ header: BoxHeader) -> Bool {
        isContainer(header.type)
    }
}
