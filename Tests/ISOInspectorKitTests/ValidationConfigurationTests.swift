import XCTest

@testable import ISOInspectorKit

final class ValidationConfigurationTests: XCTestCase {
  func testValidationRuleIdentifiersCoverKnownRules() {
    let expectedRuleIDs: Set<String> = [
      "VR-001",
      "VR-002",
      "VR-003",
      "VR-004",
      "VR-005",
      "VR-006",
      "VR-014",
      "VR-015",
      "VR-016",
      "VR-017",
      "VR-018",
    ]

    let actualRuleIDs = Set(ValidationRuleIdentifier.allCases.map(\.rawValue))
    XCTAssertEqual(actualRuleIDs, expectedRuleIDs)
  }

  func testBundledPresetsLoadDefaultManifest() throws {
    let presets = try ValidationPreset.loadBundledPresets()
    guard let defaultPreset = presets.first(where: { $0.id == "all-rules" }) else {
      XCTFail("Expected bundled manifest to provide an all-rules preset")
      return
    }

    XCTAssertEqual(defaultPreset.name, "All Checks Enabled")
    XCTAssertTrue(defaultPreset.summary.contains("Enable all validation rules"))

    for rule in ValidationRuleIdentifier.allCases {
      XCTAssertTrue(
        defaultPreset.isRuleEnabled(rule), "Rule \(rule.rawValue) should default to enabled")
    }
  }

  func testConfigurationOverridesPresetStates() throws {
    let presets = try ValidationPreset.loadBundledPresets()
    guard let structuralPreset = presets.first(where: { $0.id == "structural" }) else {
      XCTFail("Expected bundled manifest to provide a structural preset")
      return
    }

    XCTAssertFalse(structuralPreset.isRuleEnabled(.researchLogRecording))
    XCTAssertFalse(structuralPreset.isRuleEnabled(.movieDataOrdering))

    var configuration = ValidationConfiguration(activePresetID: structuralPreset.id)
    XCTAssertFalse(configuration.isRuleEnabled(.researchLogRecording, presets: presets))
    XCTAssertFalse(configuration.isRuleEnabled(.movieDataOrdering, presets: presets))

    configuration.ruleOverrides[.movieDataOrdering] = true
    XCTAssertTrue(configuration.isRuleEnabled(.movieDataOrdering, presets: presets))

    configuration.ruleOverrides[.researchLogRecording] = false
    XCTAssertFalse(configuration.isRuleEnabled(.researchLogRecording, presets: presets))
  }

  func testConfigurationCodableRoundTrip() throws {
    let configuration = ValidationConfiguration(
      activePresetID: "structural",
      ruleOverrides: [
        .movieDataOrdering: true,
        .researchLogRecording: false,
      ]
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(configuration)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ValidationConfiguration.self, from: data)

    XCTAssertEqual(decoded, configuration)
  }
}
