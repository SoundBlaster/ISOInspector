import Foundation

public struct ValidationConfiguration: Codable, Equatable, Sendable {
  public var activePresetID: String
  public var ruleOverrides: [ValidationRuleIdentifier: Bool]

  public init(activePresetID: String, ruleOverrides: [ValidationRuleIdentifier: Bool] = [:]) {
    self.activePresetID = activePresetID
    self.ruleOverrides = ruleOverrides
  }

  public func isRuleEnabled(_ rule: ValidationRuleIdentifier, presets: [ValidationPreset]) -> Bool {
    if let override = ruleOverrides[rule] {
      return override
    }

    guard let preset = presets.first(where: { $0.id == activePresetID }) else {
      return true
    }

    return preset.isRuleEnabled(rule)
  }
}
