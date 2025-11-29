import SwiftUI
import ISOInspectorKit

extension BoxCategory {
    var label: String {
        switch self {
        case .metadata: return "Metadata"
        case .media: return "Media"
        case .index: return "Index"
        case .container: return "Container"
        case .other: return "Other"
        }
    }

    var color: Color {
        switch self {
        case .metadata: return .purple
        case .media: return .green
        case .index: return .blue
        case .container: return .teal
        case .other: return .gray
        }
    }
}
