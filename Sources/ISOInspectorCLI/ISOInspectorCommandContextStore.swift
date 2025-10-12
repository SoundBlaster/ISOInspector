@MainActor enum ISOInspectorCommandContextStore {
    private static var cached = ISOInspectorCommandContext()

    static var current: ISOInspectorCommandContext {
        cached
    }

    static func bootstrap(with context: ISOInspectorCommandContext) {
        cached = context
    }

    static func reset() {
        cached = ISOInspectorCommandContext()
    }
}
