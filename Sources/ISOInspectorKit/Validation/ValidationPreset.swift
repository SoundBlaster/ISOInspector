import Foundation

public struct ValidationPreset: Codable, Equatable, Sendable {
    public struct RuleState: Codable, Equatable, Sendable {
        public let ruleID: ValidationRuleIdentifier
        public let isEnabled: Bool

        public init(ruleID: ValidationRuleIdentifier, isEnabled: Bool) {
            self.ruleID = ruleID
            self.isEnabled = isEnabled
        }
    }

    public let id: String
    public let name: String
    public let summary: String
    public let rules: [RuleState]

    private var stateByRule: [ValidationRuleIdentifier: Bool] {
        Dictionary(uniqueKeysWithValues: rules.map { ($0.ruleID, $0.isEnabled) })
    }

    public init(id: String, name: String, summary: String, rules: [RuleState] = []) {
        self.id = id
        self.name = name
        self.summary = summary
        self.rules = rules
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        summary = try container.decode(String.self, forKey: .summary)
        rules = try container.decodeIfPresent([RuleState].self, forKey: .rules) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(summary, forKey: .summary)
        if !rules.isEmpty { try container.encode(rules, forKey: .rules) }
    }

    public func isRuleEnabled(_ rule: ValidationRuleIdentifier) -> Bool {
        stateByRule[rule] ?? true
    }

    public static func loadBundledPresets(
        bundle: Bundle? = nil,
        logger: DiagnosticsLogger? = DiagnosticsLogger(
            subsystem: "ISOInspectorKit", category: "ValidationPreset")
    ) throws -> [ValidationPreset] {
        let resolvedBundle = bundle ?? .module
        guard let url = resolvedBundle.url(forResource: "ValidationPresets", withExtension: "json")
        else {
            logger?.error(
                "Validation preset manifest ValidationPresets.json is missing from bundle \(resolvedBundle)"
            )
            throw LoadingError.missingResource
        }

        do {
            let data = try Data(contentsOf: url)
            let manifest = try JSONDecoder().decode(Manifest.self, from: data)
            return manifest.presets
        } catch {
            logger?.error("Failed to decode validation preset manifest: \(error)")
            throw LoadingError.decodingFailed(underlying: error)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case summary
        case rules
    }
}

extension ValidationPreset {
    public enum LoadingError: Error {
        case missingResource
        case decodingFailed(underlying: Error)
    }

    public struct Manifest: Codable { let presets: [ValidationPreset] }
}
