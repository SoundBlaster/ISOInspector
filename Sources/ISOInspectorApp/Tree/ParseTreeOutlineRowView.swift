import Combine
import FoundationUI
import ISOInspectorKit
import NestedA11yIDs
import SwiftUI

struct ParseTreeOutlineRowView: View {
    let row: ParseTreeOutlineRow
    let isSelected: Bool
    let isBookmarked: Bool
    let isBookmarkingEnabled: Bool
    let onSelect: () -> Void
    let onToggleBookmark: () -> Void
    let onExportJSON: (@MainActor () -> Void)?
    let onExportIssueSummary: (@MainActor () -> Void)?

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            icon
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(row.displayName).font(.body).fontWeight(
                    row.isSearchMatch ? .semibold : .regular
                ).foregroundColor(row.isSearchMatch ? Color.accentColor : Color.primary)
                Text(row.typeDescription).font(.caption).foregroundColor(.secondary)
                if let summary = row.summary, !summary.isEmpty {
                    Text(summary).font(.caption2).foregroundColor(.secondary).lineLimit(2)
                }
            }
            Spacer()
            if let statusDescriptor = row.statusDescriptor {
                HStack(spacing: DS.Spacing.s) {
                    Indicator(
                        level: descriptorBadgeLevel(statusDescriptor.level), size: .mini,
                        reason: statusDescriptor.accessibilityLabel,
                        tooltip: .text(statusDescriptor.text))
                    ParseTreeStatusBadge(descriptor: statusDescriptor)
                }
            }
            if let corruption = row.corruptionSummary {
                CorruptionBadge(summary: corruption)
            } else if let severity = row.dominantSeverity {
                ParseTreeOutlineView.SeverityBadge(severity: severity)
            } else if row.hasValidationIssues {
                ParseTreeOutlineView.SeverityBadge(severity: .info)
            }
            bookmarkButton
        }.padding(.vertical, DS.Spacing.xs).padding(
            .leading, CGFloat(row.depth) * DS.Spacing.l + DS.Spacing.xxs
        ).padding(.trailing, DS.Spacing.s).frame(maxWidth: .infinity, alignment: .leading)
            .background(background).contentShape(Rectangle()).onTapGesture(perform: onSelect)
            .accessibilityElement(children: .ignore).accessibilityLabel(
                accessibilityDescriptor.label
            ).accessibilityValue(optional: accessibilityDescriptor.value).accessibilityHint(
                optional: accessibilityDescriptor.hint
            ).contextMenu {
                if let onExportJSON {
                    Button {
                        onExportJSON()
                    } label: {
                        Label("Export JSON…", systemImage: "square.and.arrow.down")
                    }
                }
                if let onExportIssueSummary {
                    Button {
                        onExportIssueSummary()
                    } label: {
                        Label("Export Issue Summary…", systemImage: "doc.text")
                    }
                }
            }
    }

    private var icon: some View {
        Group {
            if row.node.children.isEmpty {
                Image(systemName: "square").foregroundColor(.secondary)
            } else {
                Image(systemName: row.isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
            }
        }.frame(width: 12)
    }

    private var bookmarkButton: some View {
        Button(action: onToggleBookmark) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark").foregroundColor(
                isBookmarked ? Color.accentColor : Color.secondary)
        }.buttonStyle(.plain).accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
            .disabled(!isBookmarkingEnabled).opacity(isBookmarkingEnabled ? 1 : 0.35)
            .nestedAccessibilityIdentifier(
                ParseTreeAccessibilityID.Outline.List.rowBookmark(row.id))
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous).fill(backgroundColor)
    }

    private var backgroundColor: Color {
        if isSelected { return Color.accentColor.opacity(0.18) }
        if row.isSearchMatch { return Color.accentColor.opacity(0.12) }
        return Color.clear
    }

    private var accessibilityDescriptor: AccessibilityDescriptor {
        row.accessibilityDescriptor(isBookmarked: isBookmarked)
    }

    private func descriptorBadgeLevel(_ level: ParseTreeStatusDescriptor.Level) -> BadgeLevel {
        switch level {
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .success: return .success
        }
    }
}
