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

        public var displayName: String { rawValue.capitalized }
    }

    public let code: FourCharCode

    public init(code: FourCharCode) { self.code = code }

    public var rawValue: String { code.rawValue }

    public var category: Category? { HandlerType.categoryLookup[code] }

    public var displayName: String {
        if let category { return category.displayName }
        return rawValue
    }

    private static let categoryLookup: [FourCharCode: Category] = {
        var mapping: [FourCharCode: Category] = [:]

        func register(_ rawValue: String, as category: Category) {
            guard let code = try? FourCharCode(rawValue) else { return }
            mapping[code] = category
        }

        register("vide", as: .video)
        register("soun", as: .audio)
        register("hint", as: .hint)
        register("mdir", as: .metadata)
        register("meta", as: .metadata)
        register("mdta", as: .metadata)
        register("text", as: .text)
        register("subt", as: .subtitle)
        register("sbtl", as: .subtitle)
        register("clcp", as: .subtitle)
        register("capt", as: .subtitle)
        register("tmcd", as: .timecode)
        register("pict", as: .picture)
        register("alis", as: .control)
        register("auxv", as: .auxiliary)
        register("crsm", as: .clock)

        return mapping
    }()
}
