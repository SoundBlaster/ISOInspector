#if canImport(Foundation)
  import Foundation
  import ISOInspectorKit

  /// User preferences persisted across app launches.
  /// Stored in Application Support/ISOInspector/UserPreferences.json
  public struct UserPreferences: Codable, Equatable, Sendable {
    /// Active validation preset ID (e.g., "strict", "lenient")
    public var validationPresetID: String

    /// Per-rule validation overrides
    public var validationRuleOverrides: [String: Bool]

    /// Telemetry verbosity level (0 = off, 1 = minimal, 2 = full)
    public var telemetryVerbosity: Int

    /// Logging verbosity level (0 = off, 1 = errors, 2 = warnings, 3 = info, 4 = debug)
    public var loggingVerbosity: Int

    /// Reduce Motion accessibility override (nil = use system setting)
    public var reduceMotionOverride: Bool?

    /// Experimental FoundationUI features enabled by user
    public var experimentalFeatures: [String]

    /// Last active settings panel section ID
    public var lastActiveSectionID: String?

    // @todo #222 Add panel frame persistence for macOS floating window position

    public init(
      validationPresetID: String = "default",
      validationRuleOverrides: [String: Bool] = [:],
      telemetryVerbosity: Int = 0,
      loggingVerbosity: Int = 2,
      reduceMotionOverride: Bool? = nil,
      experimentalFeatures: [String] = [],
      lastActiveSectionID: String? = nil
    ) {
      self.validationPresetID = validationPresetID
      self.validationRuleOverrides = validationRuleOverrides
      self.telemetryVerbosity = telemetryVerbosity
      self.loggingVerbosity = loggingVerbosity
      self.reduceMotionOverride = reduceMotionOverride
      self.experimentalFeatures = experimentalFeatures
      self.lastActiveSectionID = lastActiveSectionID
    }

    /// Returns default user preferences.
    public static var `default`: UserPreferences {
      UserPreferences()
    }
  }
#endif
