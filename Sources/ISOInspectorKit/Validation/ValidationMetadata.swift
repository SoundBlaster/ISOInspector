import Foundation

public struct ValidationMetadata: Codable, Equatable, Sendable {
    public var activePresetID: String
    public var disabledRuleIDs: [String]

    public init(activePresetID: String, disabledRuleIDs: [String]) {
        self.activePresetID = activePresetID
        self.disabledRuleIDs = disabledRuleIDs
    }
}
