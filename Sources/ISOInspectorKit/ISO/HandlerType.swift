import Foundation

public struct HandlerType: Equatable, Hashable, Sendable {
    public enum Category: String, CaseIterable, Sendable {
        case video
        case audio
        case hint
        case metadata
        case text
        case subtitle
        case timecode
        case picture
        case control
        case auxiliary
        case clock

        public var displayName: String {
            rawValue.capitalized
        }
    }

    public let code: FourCharCode

    public init(code: FourCharCode) {
        self.code = code
    }

    public var rawValue: String {
        code.rawValue
    }

    public var category: Category? {
        HandlerType.categoryLookup[rawValue.lowercased()]
    }

    public var displayName: String {
        if let category {
            return category.displayName
        }
        return rawValue
    }

    private static let categoryLookup: [String: Category] = [
        "vide": .video,
        "soun": .audio,
        "hint": .hint,
        "mdir": .metadata,
        "meta": .metadata,
        "mdta": .metadata,
        "text": .text,
        "subt": .subtitle,
        "sbtl": .subtitle,
        "clcp": .subtitle,
        "capt": .subtitle,
        "tmcd": .timecode,
        "pict": .picture,
        "alis": .control,
        "auxv": .auxiliary,
        "crsm": .clock
    ]
}
