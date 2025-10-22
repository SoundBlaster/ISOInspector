import ISOInspectorKit

public struct ISOInspectorCommandContext: Sendable {
    public var environment: ISOInspectorCLIEnvironment
    public var verbosity: ISOInspectorCommand.GlobalOptions.Verbosity
    public var telemetryMode: ISOInspectorCommand.GlobalOptions.TelemetryMode
    public var validationConfiguration: ValidationConfiguration
    public var validationPresets: [ValidationPreset]
    public var validationConfigurationWasCustomized: Bool

    public init(
        environment: ISOInspectorCLIEnvironment = .live,
        verbosity: ISOInspectorCommand.GlobalOptions.Verbosity = .standard,
        telemetryMode: ISOInspectorCommand.GlobalOptions.TelemetryMode = .enabled,
        validationConfiguration: ValidationConfiguration = ValidationConfiguration(activePresetID: "all-rules"),
        validationPresets: [ValidationPreset] = [],
        validationConfigurationWasCustomized: Bool = false
    ) {
        self.environment = environment
        self.verbosity = verbosity
        self.telemetryMode = telemetryMode
        self.validationConfiguration = validationConfiguration
        self.validationPresets = validationPresets
        self.validationConfigurationWasCustomized = validationConfigurationWasCustomized
    }
}
