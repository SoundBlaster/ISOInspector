#if os(macOS) || os(iOS)
import SwiftUI
import FoundationUI

struct ParseTreeStatusBadge: View {
    let descriptor: ParseTreeStatusDescriptor

    var body: some View {
        Badge(text: descriptor.text.uppercased(), level: badgeLevel)
            .accessibilityLabel(descriptor.accessibilityLabel)
    }

    private var badgeLevel: BadgeLevel {
        switch descriptor.level {
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .success:
            return .success
        }
    }
}
#endif
