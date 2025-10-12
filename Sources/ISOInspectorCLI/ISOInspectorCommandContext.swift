public struct ISOInspectorCommandContext: Sendable {
    public var environment: ISOInspectorCLIEnvironment

    public init(environment: ISOInspectorCLIEnvironment = .live) {
        self.environment = environment
    }
}
