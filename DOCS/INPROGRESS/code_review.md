FoundationUI/Sources/FoundationUI/AgentSupport/YAMLParser.swift
Comment on lines 122 to +135
        public var errorDescription: String? {
            switch self {
            case .invalidYAML(let details):
                return "Invalid YAML syntax: \(details)"
            case .missingComponentType(let line):
                if let line = line {
                    return "Missing required 'componentType' field at line \(line)"
            case let .invalidYAML(details):
                "Invalid YAML syntax: \(details)"
            case let .missingComponentType(line):
                if let line {
                    "Missing required 'componentType' field at line \(line)"
                } else {
                    return "Missing required 'componentType' field"
                    "Missing required 'componentType' field"
                }
            case .invalidStructure(let details):
                return
                    "Invalid YAML structure: \(details). Expected array of component definitions or single component."
            case .fileReadError(let url, let error):
                return "Failed to read file at \(url.path): \(error.localizedDescription)"
            case let .invalidStructure(details):
                "Invalid YAML structure: \(details). Expected array of component definitions or single component."
            case let .fileReadError(url, error):
                "Failed to read file at \(url.path): \(error.localizedDescription)"
@chatgpt-codex-connector
chatgpt-codex-connector bot
3 minutes ago
 P0 Badge Return value dropped in ValidationError.errorDescription

The errorDescription computed property now switches on self without returning a value for any case. Each branch is just a bare string literal, so the property no longer produces a String? and the compiler will emit “Missing return in a function expected to return ‘String?’”. This prevents YAMLParser from compiling at all.

Useful? React with 👍 / 👎.
 @SoundBlaster	Reply...
FoundationUI/Sources/FoundationUI/AgentSupport/YAMLValidator.swift
Comment on lines 374 to +377
        static func schema(for componentType: String) -> ComponentSchema {
            switch componentType {
            case "Badge":
                return ComponentSchema(
                ComponentSchema(
@chatgpt-codex-connector
chatgpt-codex-connector bot
3 minutes ago
 P0 Badge schema(for:) no longer returns a ComponentSchema

Inside Schema.schema(for:), each switch case now constructs ComponentSchema(...) without a preceding return. Because the function’s signature promises a ComponentSchema, the compiler will complain that not all paths return a value, blocking the build.

Useful? React with 👍 / 👎.
 @SoundBlaster	Reply...
FoundationUI/Sources/FoundationUI/Utilities/AccessibilityHelpers.swift
Comment on lines 436 to +441
    /// Applies gamma correction to a color component
    private static func gammaCorrect(_ component: CGFloat) -> CGFloat {
        if component <= 0.03928 {
            return component / 12.92
            component / 12.92
        } else {
            return pow((component + 0.055) / 1.055, 2.4)
            pow((component + 0.055) / 1.055, 2.4)
@chatgpt-codex-connector
chatgpt-codex-connector bot
3 minutes ago
 P0 Badge gammaCorrect does not return CGFloat anymore

The gammaCorrect(_:) helper now uses bare expressions in the if branches instead of returning them. As written, the function provides no value for either branch, so it no longer satisfies the -> CGFloat return type and will not compile.

Useful? React with 👍 / 👎.
 @SoundBlaster	Reply...
FoundationUI/Sources/FoundationUI/Utilities/AccessibilityHelpers.swift
Comment on lines 642 to +647
    /// Maps priority to SwiftUI's accessibilitySortPriority value
    var rawValue: Double {
        switch self {
        case .low: return -1.0
        case .medium: return 0.0
        case .high: return 1.0
        case .low: -1.0
        case .medium: 0.0
        case .high: 1.0
@chatgpt-codex-connector
chatgpt-codex-connector bot
3 minutes ago
 P0 Badge AccessibilityFocusPriority.rawValue cases lack returns

The rawValue computed property now contains a switch whose cases are just numeric literals without return. The property no longer returns a Double for any path, so the compiler will emit “Missing return” errors and the accessibility utilities cannot build.
