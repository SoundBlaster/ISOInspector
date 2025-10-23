import ProjectDescription

/// ISOInspector Workspace
///
/// Unified workspace containing:
/// - ISOInspector: Main application (iOS, iPadOS, macOS) and CLI tools
/// - FoundationUI: SwiftUI component library
/// - ComponentTestApp: Demo app for FoundationUI testing
///
/// ## Usage
/// ```bash
/// tuist generate
/// open ISOInspector.xcworkspace
/// ```

let workspace = Workspace(
    name: "ISOInspector",
    projects: [
        ".",                                // ISOInspector main project
        "FoundationUI",                     // FoundationUI framework
        "Examples/ComponentTestApp"         // ComponentTestApp demo
    ]
)
