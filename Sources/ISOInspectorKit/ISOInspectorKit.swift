public enum ISOInspectorKit {
    public static let projectName = "ISOInspector"

    /// Lightweight description of the first execution areas pulled from the PRD backlog.
    public static let initialFocusAreas: [String] = [
        "Phase A · IO Foundations", "Phase B · Box Parser Core", "Phase C · SwiftUI App Shell",
        "Phase D · CLI Experience",
    ]

    public static func welcomeMessage() -> String {
        (["Welcome to \(projectName)!"] + ["Initial focus areas:"]
            + initialFocusAreas.map { "  • \($0)" }).joined(separator: "\n")
    }
}
