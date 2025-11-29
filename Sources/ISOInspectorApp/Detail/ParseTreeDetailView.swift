#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Foundation
import NestedA11yIDs
import ISOInspectorKit
import FoundationUI

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

struct ParseTreeDetailView: View {
    @ObservedObject var viewModel: ParseTreeDetailViewModel
    @ObservedObject var annotationSession: AnnotationBookmarkSession
    @Binding var selectedNodeID: ParseTreeNode.ID?
    @State private var draftNote: String = ""
    private let bytesPerRow = 16
    let focusTarget: FocusState<InspectorFocusTarget?>.Binding

    var body: some View {
        ScrollView {
            header

            content
        }
        .onChangeCompatibility(of: selectedNodeID) { _ in
            draftNote = ""
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Selection Details")
                    .font(.title3)
                    .bold()
                Text("View metadata validation issues, and payload bytes for the selected box.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.m)
        .padding(.top, DS.Spacing.m)
    }

    @ViewBuilder
    private var content: some View {
        if let detail = viewModel.detail {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                metadataSection(detail: detail)
                corruptionSection(detail: detail)
                encryptionSection(detail: detail)
                userNotesSection()
                fieldAnnotationSection()
                validationSection(detail: detail)
                hexSection(detail: detail)
            }
            .padding(DS.Spacing.m)
//            .frame(maxWidth: .infinity, alignment: .leading)
            .dynamicTypeSize(.medium ... .accessibility5)
        } else {
            noSelectionView
        }
    }

    @ViewBuilder
    private var noSelectionView: some View {
        if #available(iOS 17, macOS 14, *) {
            ContentUnavailableView(
                "No selection",
                systemImage: "square.dashed",
                description: Text("Choose a box in the hierarchy to inspect its details.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: DS.Spacing.m) {
                Image(systemName: "square.dashed")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                Text("No selection")
                    .font(.headline)
                Text("Choose a box in the hierarchy to inspect its details.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func metadataSection(detail: ParseTreeNodeDetail) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader(title: "Metadata", icon: "info.circle")
                Spacer()
                bookmarkControl()
            }
            metadataGrid(detail: detail)
            Text("Snapshot updated ")
            + Text(detail.snapshotTimestamp, style: .relative)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(detail.accessibilitySummary)
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.metadata)
    }

    private func metadataGrid(detail: ParseTreeNodeDetail) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            BoxMetadataRow(label: "Type", value: detail.header.identifierString)
            metadataStatusRow(status: detail.status)
            BoxMetadataRow(label: "Range", value: byteRangeString(for: detail.header.range))
            BoxMetadataRow(label: "Payload", value: byteRangeString(for: detail.header.payloadRange))
            if let name = detail.metadata?.name, !name.isEmpty {
                BoxMetadataRow(label: "Name", value: name)
            }
            if let summary = detail.metadata?.summary, !summary.isEmpty {
                BoxMetadataRow(
                    label: "Summary",
                    value: summary,
                    layout: .vertical
                )
            }
            if let specification = detail.metadata?.specification, !specification.isEmpty {
                BoxMetadataRow(
                    label: "Spec",
                    value: specification,
                    layout: .vertical
                )
            }
            if let version = detail.metadata?.version {
                BoxMetadataRow(label: "Version", value: "v\(version)")
            }
            if let flags = detail.metadata?.flags {
                BoxMetadataRow(
                    label: "Flags",
                    value: "0x\(String(flags, radix: 16, uppercase: true))",
                    copyable: true
                )
            }
        }
    }

    @ViewBuilder
    private func metadataStatusRow(status: ParseTreeNode.Status) -> some View {
        if let descriptor = ParseTreeStatusDescriptor(status: status) {
            HStack(spacing: DS.Spacing.m) {
                Text("Status")
                    .font(DS.Typography.body)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: DS.Spacing.s) {
                    Indicator(
                        level: descriptorBadgeLevel(descriptor.level),
                        size: .small,
                        reason: descriptor.accessibilityLabel,
                        tooltip: .text(descriptor.text)
                    )
                    ParseTreeStatusBadge(descriptor: descriptor)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(descriptor.accessibilityLabel)
        } else {
            BoxMetadataRow(label: "Status", value: status.rawValue.capitalized)
        }
    }

    private func descriptorBadgeLevel(_ level: ParseTreeStatusDescriptor.Level) -> BadgeLevel {
        switch level {
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

    @ViewBuilder
    private func encryptionSection(detail: ParseTreeNodeDetail) -> some View {
        let summary = EncryptionSummary(detail: detail)
        if summary.hasContent {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                sectionHeader(title: "Encryption Metadata", icon: "lock.shield")
                if !summary.sampleEncryption.isEmpty {
                    encryptionSubsection(title: "Sample Encryption (senc)", rows: summary.sampleEncryption)
                }
                if !summary.auxInfoOffsets.isEmpty {
                    encryptionSubsection(title: "Aux Info Offsets (saio)", rows: summary.auxInfoOffsets)
                }
                if !summary.auxInfoSizes.isEmpty {
                    encryptionSubsection(title: "Aux Info Sizes (saiz)", rows: summary.auxInfoSizes)
                }
            }
            .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.encryption)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(summary.accessibilityLabel)
        }
    }

    @ViewBuilder
    private func corruptionSection(detail: ParseTreeNodeDetail) -> some View {
        if detail.issues.isEmpty {
            EmptyView()
        } else {
            CorruptionIssueSection(
                header: AnyView(sectionHeader(title: "Corruption", icon: "exclamationmark.triangle")),
                statusDescriptor: ParseTreeStatusDescriptor(status: detail.status),
                issues: detail.issues,
                focusTarget: focusTarget,
                onCopy: copyToClipboard,
                onViewInHex: { range in
                    viewModel.focusIssue(on: range)
                },
                rangeFormatter: corruptionRangeDescription(for:)
            )
            .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.corruption)
        }
    }

    private func encryptionSubsection(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    BoxMetadataRow(label: row.0, value: row.1)
                }
            }
        }
    }

    private struct CorruptionIssueSection: View {
        let header: AnyView
        let statusDescriptor: ParseTreeStatusDescriptor?
        let issues: [ParseIssue]
        let focusTarget: FocusState<InspectorFocusTarget?>.Binding
        let onCopy: (String) -> Void
        let onViewInHex: (Range<Int64>) -> Void
        let rangeFormatter: (Range<Int64>) -> String

        var body: some View {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                HStack(alignment: .center, spacing: DS.Spacing.s) {
                    header
                    if let statusDescriptor {
                        ParseTreeStatusBadge(descriptor: statusDescriptor)
                    }
                }
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
                        CorruptionIssueRow(
                            issue: issue,
                            focusTarget: focusTarget,
                            onCopy: onCopy,
                            onViewInHex: onViewInHex,
                            rangeFormatter: rangeFormatter
                        )
                    }
                }
            }
        }
    }

    private struct CorruptionIssueRow: View {
        let issue: ParseIssue
        let focusTarget: FocusState<InspectorFocusTarget?>.Binding
        let onCopy: (String) -> Void
        let onViewInHex: (Range<Int64>) -> Void
        let rangeFormatter: (Range<Int64>) -> String

        var body: some View {
            Group {
                if let range = issue.byteRange {
                    baseRow
                        .accessibilityAction {
                            focusTarget.wrappedValue = .hex
                            onViewInHex(range)
                        }
                        .accessibilityAction(named: Text("View in Hex")) {
                            focusTarget.wrappedValue = .hex
                            onViewInHex(range)
                        }
                } else {
                    baseRow
                }
            }
            .accessibilityAction(named: Text("Copy Message")) {
                onCopy(issue.message)
            }
        }

        private var baseRow: some View {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s) {
                    Image(systemName: issue.severity.iconName)
                        .foregroundColor(issue.severity.color)
                        .font(.title3.weight(.semibold))
                        .accessibilityHidden(true)
                    Text(issue.code)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .textSelection(.enabled)
                    Spacer()
                    if let range = issue.byteRange {
                        Button {
                            focusTarget.wrappedValue = .hex
                            onViewInHex(range)
                        } label: {
                            Label("View in Hex", systemImage: "viewfinder")
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    Button {
                        onCopy(issue.message)
                    } label: {
                        Label("Copy Message", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                Text(issue.message)
                    .font(.body)
                    .textSelection(.enabled)
                if let range = issue.byteRange {
                    Text(rangeFormatter(range))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                } else {
                    Text("No byte range reported.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(DS.Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                issue.severity.color.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(issue.severity.color.opacity(0.3), lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(
                issue.byteRange != nil ? Text("Double-tap to view the highlighted hex range.") : Text(""))
        }

        private var accessibilityLabel: String {
            var components: [String] = [
                "\(issue.severity.accessibilityDescription) issue",
                issue.code,
                issue.message,
            ]
            if let range = issue.byteRange {
                components.append(rangeFormatter(range))
            } else {
                components.append("Byte range unavailable")
            }
            return components.joined(separator: ". ")
        }
    }

    private func bookmarkControl() -> some View {
        Button {
            annotationSession.toggleBookmark()
        } label: {
            Label(
                annotationSession.isSelectedNodeBookmarked ? "Bookmarked" : "Bookmark",
                systemImage: annotationSession.isSelectedNodeBookmarked ? "bookmark.fill" : "bookmark"
            )
        }
        .buttonStyle(.bordered)
        .disabled(!annotationSession.isEnabled || selectedNodeID == nil)
        .accessibilityLabel(
            annotationSession.isSelectedNodeBookmarked ? "Remove bookmark" : "Add bookmark"
        )
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.bookmarkButton)
    }

    @ViewBuilder
    private func fieldAnnotationSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            sectionHeader(title: "Fields", icon: "list.bullet.rectangle")
            if let error = viewModel.annotationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            if viewModel.annotations.isEmpty && viewModel.annotationError == nil {
                Text("No field annotations available for this selection.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    ForEach(viewModel.annotations) { annotation in
                        annotationRow(annotation)
                    }
                }
            }
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.fieldAnnotations)
    }

    @ViewBuilder
    private func userNotesSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            sectionHeader(title: "Notes", icon: "note.text")
            if !annotationSession.isStoreAvailable {
                Text("Notes are unavailable on this platform.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if !annotationSession.isEnabled || selectedNodeID == nil {
                Text("Select a box in a parsed file to add notes and bookmarks.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                if let message = annotationSession.lastErrorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if annotationSession.activeAnnotations.isEmpty {
                    Text("No notes yet. Add your first note below.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        ForEach(annotationSession.activeAnnotations) { record in
                            AnnotationNoteRow(
                                record: record,
                                onUpdate: { updated in
                                    annotationSession.updateAnnotation(id: record.id, note: updated)
                                },
                                onDelete: {
                                    annotationSession.deleteAnnotation(id: record.id)
                                }
                            )
                        }
                    }
                }
                noteComposer
            }
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.notes)
    }

    private var noteComposer: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text("Add note")
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: $draftNote)
                .frame(minHeight: 72)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.2))
                }
                .focused(focusTarget, equals: .notes)
            HStack {
                Spacer()
                Button("Save") {
                    submitNote()
                }
                .buttonStyle(.borderedProminent)
                .disabled(draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func submitNote() {
        let trimmed = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        annotationSession.addAnnotation(note: trimmed)
        draftNote = ""
    }

    private func annotationRow(_ annotation: PayloadAnnotation) -> some View {
        let isSelected = viewModel.selectedAnnotationID == annotation.id
        return Button {
            viewModel.select(annotationID: annotation.id)
        } label: {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(annotation.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(annotation.formattedRange)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(annotation.value)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                if let summary = annotation.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.s)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.06))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    isSelected ? Color.accentColor : Color.gray.opacity(0.2),
                    lineWidth: isSelected ? 1 : 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(annotationAccessibilityLabel(for: annotation))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func annotationAccessibilityLabel(for annotation: PayloadAnnotation) -> String {
        var components: [String] = [annotation.label, annotation.formattedRange, annotation.value]
        if let summary = annotation.summary, !summary.isEmpty {
            components.append(summary)
        }
        return components.joined(separator: ". ")
    }

    private func validationSection(detail: ParseTreeNodeDetail) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            sectionHeader(title: "Validation", icon: "checkmark.shield")
            if detail.validationIssues.isEmpty {
                Text("No validation issues detected.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    ForEach(Array(detail.validationIssues.enumerated()), id: \.offset) { _, issue in
                        validationRow(issue: issue)
                    }
                }
            }
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.validation)
    }

    private func validationRow(issue: ValidationIssue) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            HStack(spacing: 8) {
                SeverityBadge(severity: issue.severity)
                Text(issue.ruleID)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    copyToClipboard(issue.message)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            Text(issue.message)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(DS.Spacing.s)
        .background(
            Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(issue.ruleID). \(issue.severity.accessibilityDescription). \(issue.message)")
    }

    private func hexSection(detail: ParseTreeNodeDetail) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            sectionHeader(title: "Hex", icon: "rectangle.grid.1x2")
            if let error = viewModel.hexError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            if let slice = detail.hexSlice, !slice.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Offsets \(slice.offset) – \(slice.endOffset)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HexSliceView(
                        slice: slice,
                        highlightedRange: viewModel.highlightedRange,
                        bytesPerRow: bytesPerRow,
                        focusTarget: focusTarget,
                        onSelectOffset: { viewModel.selectByte(at: $0) }
                    )
                }
            } else {
                Text("No payload bytes available for this selection.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.hexView)
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
        }
    }

    private func byteRangeString(for range: Range<Int64>) -> String {
        "\(range.lowerBound) – \(range.upperBound)"
    }

    private func corruptionRangeDescription(for range: Range<Int64>) -> String {
        let length = max(0, range.upperBound - range.lowerBound)
        return "Bytes \(range.lowerBound) – \(range.upperBound) (length \(length))"
    }

    private func copyToClipboard(_ text: String) {
#if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
#elseif canImport(UIKit)
        UIPasteboard.general.string = text
#endif
    }
}

private struct HexSliceView: View {
    let slice: HexSlice
    let highlightedRange: Range<Int64>?
    let bytesPerRow: Int
    let focusTarget: FocusState<InspectorFocusTarget?>.Binding
    let onSelectOffset: (Int64) -> Void

    @State private var focusedOffset: Int64?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.vertical, .horizontal]) {
                LazyVStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    ForEach(rows) { row in
                        HexSliceRowView(
                            row: row,
                            bytesPerRow: bytesPerRow,
                            highlightedRange: highlightedRange,
                            focusTarget: focusTarget,
                            onSelectOffset: { select(offset: $0) }
                        )
                        .id(row.index)
                    }
                }
                .padding(DS.Spacing.s)
            }
            .frame(minHeight: 200, idealHeight: 240, maxHeight: 320)
            .background(
                Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .onChangeCompatibility(of: highlightedRange) { newValue in
                guard let range = newValue, let id = rowID(for: range) else { return }
                DispatchQueue.main.async {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
            .focused(focusTarget, equals: .hex)
            .compatibilityFocusable()
            .onAppear {
                focusedOffset = highlightedRange?.lowerBound
            }
            .onChangeCompatibility(of: highlightedRange) { newValue in
                focusedOffset = newValue?.lowerBound
            }
#if canImport(AppKit)
            .onMoveCommand { direction in
                guard focusTarget.wrappedValue == .hex else { return }
                guard let offset = focusedOffset ?? highlightedRange?.lowerBound else { return }
                guard let nextOffset = nextOffset(from: offset, direction: direction) else { return }
                select(offset: nextOffset)
                scrollToOffset(nextOffset, proxy: proxy)
            }
#endif
        }
    }

    private var rows: [HexSliceRow] {
        guard bytesPerRow > 0 else { return [] }
        let bytes = Array(slice.bytes)
        return stride(from: 0, to: bytes.count, by: bytesPerRow).enumerated().map { index, start in
            let end = min(start + bytesPerRow, bytes.count)
            let offset = slice.offset + Int64(start)
            return HexSliceRow(index: index, offset: offset, bytes: Array(bytes[start..<end]))
        }
    }

    private func rowID(for range: Range<Int64>) -> Int? {
        guard !rows.isEmpty else { return nil }
        let clampedStart = max(range.lowerBound, slice.offset)
        guard clampedStart < slice.endOffset else { return nil }
        let relative = clampedStart - slice.offset
        guard relative >= 0 else { return nil }
        let row = Int(relative) / bytesPerRow
        return min(max(row, 0), rows.count - 1)
    }

    private func select(offset: Int64) {
        focusTarget.wrappedValue = .hex
        focusedOffset = offset
        onSelectOffset(offset)
    }

#if canImport(AppKit)
    private func nextOffset(from offset: Int64, direction: MoveCommandDirection) -> Int64? {
        switch direction {
        case .left:
            let target = offset - 1
            return target >= slice.offset ? target : nil
        case .right:
            let target = offset + 1
            return target < slice.endOffset ? target : nil
        case .up:
            let target = offset - Int64(bytesPerRow)
            return target >= slice.offset ? target : nil
        case .down:
            let target = offset + Int64(bytesPerRow)
            return target < slice.endOffset ? target : nil
        default:
            return nil
        }
    }
#endif

    private func scrollToOffset(_ offset: Int64, proxy: ScrollViewProxy) {
        if let id = rowID(for: offset..<(offset + 1)) {
            DispatchQueue.main.async {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }
}

private struct EncryptionSummary {
    let sampleEncryption: [(String, String)]
    let auxInfoOffsets: [(String, String)]
    let auxInfoSizes: [(String, String)]

    var hasContent: Bool {
        !sampleEncryption.isEmpty || !auxInfoOffsets.isEmpty || !auxInfoSizes.isEmpty
    }

    var accessibilityLabel: String {
        var segments: [String] = []
        func append(_ title: String, rows: [(String, String)]) {
            guard !rows.isEmpty else { return }
            segments.append(title)
            for (label, value) in rows {
                segments.append("\(label) \(value)")
            }
        }
        append("Sample encryption", rows: sampleEncryption)
        append("Aux info offsets", rows: auxInfoOffsets)
        append("Aux info sizes", rows: auxInfoSizes)
        return segments.joined(separator: ". ")
    }

    init(detail: ParseTreeNodeDetail) {
        func rangeString(_ range: Range<Int64>) -> String {
            "\(range.lowerBound) – \(range.upperBound)"
        }

        func yesNo(_ value: Bool) -> String {
            value ? "Yes" : "No"
        }

        var sampleRows: [(String, String)] = []
        if let encryption = detail.payload?.sampleEncryption {
            sampleRows.append(("Entries", "\(encryption.sampleCount)"))
            sampleRows.append(("Overrides Defaults", yesNo(encryption.overrideTrackEncryptionDefaults)))
            sampleRows.append(("Subsample Encryption", yesNo(encryption.usesSubsampleEncryption)))
            if let ivSize = encryption.perSampleIVSize {
                sampleRows.append(("Per-Sample IV Size", "\(ivSize)"))
            }
            if let algorithm = encryption.algorithmIdentifier {
                sampleRows.append(("Algorithm ID", String(format: "0x%06X", algorithm)))
            }
            if let keyRange = encryption.keyIdentifierRange {
                sampleRows.append(("Key Identifier Range", rangeString(keyRange)))
            }
            if let sampleBytes = encryption.sampleInfoByteLength {
                sampleRows.append(("Sample Info Bytes", "\(sampleBytes)"))
            }
            if let sampleRange = encryption.sampleInfoRange {
                sampleRows.append(("Sample Info Range", rangeString(sampleRange)))
            }
            if let constantBytes = encryption.constantIVByteLength {
                sampleRows.append(("Constant IV Bytes", "\(constantBytes)"))
            }
            if let constantRange = encryption.constantIVRange {
                sampleRows.append(("Constant IV Range", rangeString(constantRange)))
            }
        }
        self.sampleEncryption = sampleRows

        var offsetRows: [(String, String)] = []
        if let offsets = detail.payload?.sampleAuxInfoOffsets {
            offsetRows.append(("Entries", "\(offsets.entryCount)"))
            offsetRows.append(("Bytes Per Entry", "\(offsets.entrySizeBytes)"))
            if let type = offsets.auxInfoType?.rawValue, !type.isEmpty {
                offsetRows.append(("Aux Info Type", type))
            }
            if let parameter = offsets.auxInfoTypeParameter {
                offsetRows.append(("Type Parameter", "\(parameter)"))
            }
            if let entriesBytes = offsets.entriesByteLength {
                offsetRows.append(("Entries Bytes", "\(entriesBytes)"))
            }
            if let entriesRange = offsets.entriesRange {
                offsetRows.append(("Entries Range", rangeString(entriesRange)))
            }
        }
        self.auxInfoOffsets = offsetRows

        var sizeRows: [(String, String)] = []
        if let sizes = detail.payload?.sampleAuxInfoSizes {
            sizeRows.append(("Default Size", "\(sizes.defaultSampleInfoSize)"))
            sizeRows.append(("Entry Count", "\(sizes.entryCount)"))
            if let type = sizes.auxInfoType?.rawValue, !type.isEmpty {
                sizeRows.append(("Aux Info Type", type))
            }
            if let parameter = sizes.auxInfoTypeParameter {
                sizeRows.append(("Type Parameter", "\(parameter)"))
            }
            if let variableBytes = sizes.variableEntriesByteLength {
                sizeRows.append(("Variable Bytes", "\(variableBytes)"))
            }
            if let variableRange = sizes.variableEntriesRange {
                sizeRows.append(("Variable Range", rangeString(variableRange)))
            }
        }
        self.auxInfoSizes = sizeRows
    }
}

private struct HexSliceRow: Identifiable {
    let index: Int
    let offset: Int64
    let bytes: [UInt8]

    var id: Int { index }
}

private struct HexSliceRowView: View {
    let row: HexSliceRow
    let bytesPerRow: Int
    let highlightedRange: Range<Int64>?
    let focusTarget: FocusState<InspectorFocusTarget?>.Binding
    let onSelectOffset: (Int64) -> Void

    private var hexColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(28), spacing: DS.Spacing.xxs), count: bytesPerRow)
    }

    private let accessibilityFormatter = HexByteAccessibilityFormatter()

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.m) {
            Text(String(format: "%08llX", UInt64(max(0, row.offset))))
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            LazyVGrid(columns: hexColumns, spacing: DS.Spacing.xxs) {
                ForEach(0..<bytesPerRow, id: \.self) { index in
                    if index < row.bytes.count {
                        let globalOffset = row.offset + Int64(index)
                        let label = accessibilityFormatter.label(
                            for: row.bytes[index],
                            at: globalOffset,
                            highlighted: isHighlighted(globalOffset)
                        )
                        HexByteCell(
                            text: String(format: "%02X", row.bytes[index]),
                            isHighlighted: isHighlighted(globalOffset),
                            width: 28,
                            accessibilityLabel: label
                        ) {
                            focusTarget.wrappedValue = .hex
                            onSelectOffset(globalOffset)
                        }
                    } else {
                        Spacer().frame(width: 28, height: 24)
                    }
                }
            }

            Divider()
                .frame(height: 24)

            HStack(spacing: 2) {
                ForEach(0..<bytesPerRow, id: \.self) { index in
                    if index < row.bytes.count {
                        let globalOffset = row.offset + Int64(index)
                        HexByteCell(
                            text: asciiCharacter(for: row.bytes[index]),
                            isHighlighted: isHighlighted(globalOffset),
                            width: 16,
                            accessibilityLabel: accessibilityFormatter.label(
                                for: row.bytes[index],
                                at: globalOffset,
                                highlighted: isHighlighted(globalOffset)
                            )
                        ) {
                            onSelectOffset(globalOffset)
                        }
                        .accessibilityHidden(true)
                    } else {
                        Spacer().frame(width: 16, height: 24)
                    }
                }
            }
            .font(.system(.body, design: .monospaced))
        }
    }

    private func isHighlighted(_ offset: Int64) -> Bool {
        highlightedRange?.contains(offset) ?? false
    }

    private func asciiCharacter(for byte: UInt8) -> String {
        let value = Int(byte)
        if (32...126).contains(value), let scalar = UnicodeScalar(value) {
            return String(Character(scalar))
        }
        return "."
    }
}

private struct HexByteCell: View {
    let text: String
    let isHighlighted: Bool
    let width: CGFloat
    let accessibilityLabel: String
    let onTap: () -> Void

    init(
        text: String, isHighlighted: Bool, width: CGFloat, accessibilityLabel: String,
        onTap: @escaping () -> Void
    ) {
        self.text = text
        self.isHighlighted = isHighlighted
        self.width = width
        self.accessibilityLabel = accessibilityLabel
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(.body, design: .monospaced))
                .frame(width: width, height: 24)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(isHighlighted ? Color.accentColor.opacity(0.25) : Color.clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(
                    isHighlighted ? Color.accentColor : Color.gray.opacity(0.2),
                    lineWidth: isHighlighted ? 1 : 0.5)
        }
        .contentShape(Rectangle())
        .accessibilityAddTraits(isHighlighted ? .isSelected : [])
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct AnnotationNoteRow: View {
    let record: AnnotationRecord
    let onUpdate: (String) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var draft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("Updated " + record.updatedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if isEditing {
                    Button("Cancel") {
                        isEditing = false
                        draft = record.note
                    }
                    .font(.caption)
                    .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.Notes.Controls.cancel)
                    Button("Save") {
                        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onUpdate(trimmed)
                        isEditing = false
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.Notes.Controls.save)
                } else {
                    Button("Edit") {
                        draft = record.note
                        isEditing = true
                    }
                    .font(.caption)
                    .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.Notes.Controls.edit)
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .accessibilityLabel("Delete note")
                    .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.Notes.Controls.delete)
                }
            }
            .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.Notes.Controls.root)
            if isEditing {
                TextEditor(text: $draft)
                    .frame(minHeight: 60)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.gray.opacity(0.2))
                    }
            } else {
                Text(record.note)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
        .padding(DS.Spacing.s)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.gray.opacity(0.08))
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.Notes.row(record.id))
        .onAppear {
            draft = record.note
        }
        .onChangeCompatibility(of: record.note) { newValue in
            if !isEditing {
                draft = newValue
            }
        }
    }
}

private struct SeverityBadge: View {
    let severity: ValidationIssue.Severity

    var body: some View {
        Text(severity.label.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, DS.Spacing.xs)
            .padding(.vertical, DS.Spacing.xs / 2)
            .background(severity.color.opacity(0.2))
            .foregroundColor(severity.color)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
    }
}

extension ParseIssue.Severity {
    fileprivate var color: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }

    fileprivate var iconName: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }

    fileprivate var accessibilityDescription: String {
        switch self {
        case .info:
            return "Informational"
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        }
    }
}
#endif
