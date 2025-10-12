import Foundation

public struct PerformanceBenchmarkConfiguration: Sendable {
    public enum Intensity: String, Sendable {
        case ci
        case local
    }

    private enum EnvironmentKey {
        static let intensity = "ISOINSPECTOR_BENCHMARK_INTENSITY"
        static let payloadBytes = "ISOINSPECTOR_BENCHMARK_PAYLOAD_BYTES"
        static let iterationCount = "ISOINSPECTOR_BENCHMARK_ITERATIONS"
        static let slackMultiplier = "ISOINSPECTOR_BENCHMARK_SLACK"
    }

    private static let referenceBytes: Double = 4 * 1024 * 1024 * 1024
    private static let referenceSeconds: Double = 45
    private static let uiLatencySeconds: Double = 0.2
    private static let defaultPayloadBytes = 32 * 1_048_576
    private static let localPayloadBytes = 64 * 1_048_576
    private static let defaultIterationCount = 3
    private static let localIterationCount = 5
    private static let defaultSlack: Double = 1.5
    private static let localSlack: Double = 1.2

    public let intensity: Intensity
    public let payloadBytes: Int
    public let iterationCount: Int
    public let slackMultiplier: Double

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        let intensity = Intensity(rawValue: environment[EnvironmentKey.intensity]?.lowercased() ?? "") ?? .ci
        self.intensity = intensity

        var payload: Int
        var iterations: Int
        var slack: Double

        switch intensity {
        case .ci:
            payload = Self.defaultPayloadBytes
            iterations = Self.defaultIterationCount
            slack = Self.defaultSlack
        case .local:
            payload = Self.localPayloadBytes
            iterations = Self.localIterationCount
            slack = Self.localSlack
        }

        if let override = environment[EnvironmentKey.payloadBytes], let value = Int(override), value > 0 {
            payload = value
        }

        if let override = environment[EnvironmentKey.iterationCount], let value = Int(override), value > 0 {
            iterations = value
        }

        if let override = environment[EnvironmentKey.slackMultiplier], let value = Double(override), value >= 1 {
            slack = value
        }

        payloadBytes = payload
        iterationCount = iterations
        slackMultiplier = slack
    }

    public func cliDurationBudgetSeconds() -> TimeInterval {
        let baseSeconds = Double(payloadBytes) * Self.referenceSeconds / Self.referenceBytes
        return baseSeconds * slackMultiplier
    }

    public func uiLatencyBudgetSeconds() -> TimeInterval {
        Self.uiLatencySeconds * slackMultiplier
    }
}
