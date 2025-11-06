/// ComponentTestApp - Demo Application for FoundationUI Components
///
/// A minimal demo application showcasing all implemented FoundationUI components
/// with interactive examples, live preview capabilities, and comprehensive documentation.
///
/// Supports: iOS 17+, macOS 14+
/// Architecture: SwiftUI universal app
///
/// Features:
/// - Component showcase screens for all FoundationUI components
/// - Interactive controls (Light/Dark mode, Dynamic Type)
/// - Live preview of component variations
/// - Code snippet export capability

import FoundationUI
import SwiftUI

/// Theme preference options (must match ContentView definition)
enum ThemePreference: Int {
    case system = 0
    case light = 1
    case dark = 2
}

@main
struct ComponentTestApp: App {
    /// Current Dynamic Type size category
    @State private var sizeCategory: DynamicTypeSize = .medium

    var body: some Scene {
        WindowGroup {
            ContentView()
                .dynamicTypeSize(sizeCategory)
        }
        #if os(macOS)
            .windowStyle(.automatic)
            .windowToolbarStyle(.unified)
        #endif
    }
}
