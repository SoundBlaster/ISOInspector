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

/// Dynamic Type size preference wrapper for AppStorage
enum DynamicTypeSizePreference: Int, CaseIterable {
    case xSmall = 0
    case small = 1
    case medium = 2
    case large = 3
    case xLarge = 4
    case xxLarge = 5
    case xxxLarge = 6
    case accessibility1 = 7
    case accessibility2 = 8
    case accessibility3 = 9
    case accessibility4 = 10
    case accessibility5 = 11

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .xSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .xLarge
        case .xxLarge: return .xxLarge
        case .xxxLarge: return .xxxLarge
        case .accessibility1: return .accessibility1
        case .accessibility2: return .accessibility2
        case .accessibility3: return .accessibility3
        case .accessibility4: return .accessibility4
        case .accessibility5: return .accessibility5
        }
    }

    init(from dynamicTypeSize: DynamicTypeSize) {
        switch dynamicTypeSize {
        case .xSmall: self = .xSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .xLarge: self = .xLarge
        case .xxLarge: self = .xxLarge
        case .xxxLarge: self = .xxxLarge
        case .accessibility1: self = .accessibility1
        case .accessibility2: self = .accessibility2
        case .accessibility3: self = .accessibility3
        case .accessibility4: self = .accessibility4
        case .accessibility5: self = .accessibility5
        @unknown default: self = .medium
        }
    }
}

@main struct ComponentTestApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }#if os(macOS)
            .windowStyle(.automatic).windowToolbarStyle(.unified)
            #endif
    }
}
