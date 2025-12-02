import Combine
import FoundationUI
import ISOInspectorKit
import NestedA11yIDs
import SwiftUI

struct CorruptionBadge: View {
    let summary: ParseTreeOutlineRow.CorruptionSummary

    var body: some View {
        Badge(text: summary.badgeText, level: badgeLevel, showIcon: true).help(
            summary.tooltipText ?? summary.badgeText
        ).accessibilityElement(children: .ignore).accessibilityLabel(summary.accessibilityLabel)
            .accessibilityHint(optional: summary.accessibilityHint)#if os(macOS)
                .focusable(true)
            #endif
    }

    private var badgeLevel: BadgeLevel {
        switch summary.dominantSeverity {
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        }
    }
}
