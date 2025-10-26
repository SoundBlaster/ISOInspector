#if canImport(SwiftUI)
import SwiftUI

struct ParseTreeStatusBadge: View {
    let descriptor: ParseTreeStatusDescriptor

    var body: some View {
        Text(descriptor.text.uppercased())
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .foregroundStyle(colors.foreground)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(colors.background)
            )
            .accessibilityLabel(descriptor.accessibilityLabel)
    }

    private var colors: (foreground: Color, background: Color) {
        switch descriptor.level {
        case .info:
            return (.blue, Color.blue.opacity(0.15))
        case .warning:
            return (.orange, Color.orange.opacity(0.2))
        case .error:
            return (.red, Color.red.opacity(0.2))
        case .success:
            return (.green, Color.green.opacity(0.2))
        }
    }
}
#endif
