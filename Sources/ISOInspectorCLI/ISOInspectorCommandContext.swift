public struct ISOInspectorCommandContext: Sendable {
    public var environment: ISOInspectorCLIEnvironment
    public var verbosity: ISOInspectorCommand.GlobalOptions.Verbosity
    public var telemetryMode: ISOInspectorCommand.GlobalOptions.TelemetryMode

    public init(
        environment: ISOInspectorCLIEnvironment = .live,
        verbosity: ISOInspectorCommand.GlobalOptions.Verbosity = .standard,
        telemetryMode: ISOInspectorCommand.GlobalOptions.TelemetryMode = .enabled
    ) {
        self.environment = environment
        self.verbosity = verbosity
        self.telemetryMode = telemetryMode
    }
}
