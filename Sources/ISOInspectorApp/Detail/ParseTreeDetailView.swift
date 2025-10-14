#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import NestedA11yIDs

#if canImport(ISOInspectorKit_iOS)
import ISOInspectorKit_iOS
#endif
#if canImport(ISOInspectorKit_macOS)
import ISOInspectorKit_macOS
#endif
#if canImport(ISOInspectorKit_ipadOS)
import ISOInspectorKit_ipadOS
#endif

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
        VStack(alignment: .leading, spacing: 12) {
            header
            content
        }
        .onChange(of: selectedNodeID) { _, _ in
            draftNote = ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Selection Details")
                .font(.title3)
                .bold()
            Text("View metadata, validation issues, and payload bytes for the selected box.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let detail = viewModel.detail {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    metadataSection(detail: detail)
                    userNotesSection()
                    fieldAnnotationSection()
                    validationSection(detail: detail)
                    hexSection(detail: detail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .dynamicTypeSize(.medium ... .accessibility5)
        } else {
            ContentUnavailableView(
                "No selection",
                systemImage: "square.dashed",
                description: Text("Choose a box in the hierarchy to inspect its details.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func metadataSection(detail: ParseTreeNodeDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader(title: "Metadata", icon: "info.circle")
                Spacer()
                bookmarkControl()
            }
            metadataGrid(detail: detail)
            Text("Snapshot updated ") + Text(detail.snapshotTimestamp, style: .relative)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(detail.accessibilitySummary)
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.metadata)
    }

    private func metadataGrid(detail: ParseTreeNodeDetail) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
            metadataRow(label: "Type", value: detail.header.identifierString)
            metadataRow(label: "Range", value: byteRangeString(for: detail.header.range))
            metadataRow(label: "Payload", value: byteRangeString(for: detail.header.payloadRange))
            if let name = detail.metadata?.name, !name.isEmpty {
                metadataRow(label: "Name", value: name)
            }
            if let summary = detail.metadata?.summary, !summary.isEmpty {
                metadataRow(label: "Summary", value: summary)
            }
            if let specification = detail.metadata?.specification, !specification.isEmpty {
                metadataRow(label: "Spec", value: specification)
            }
            if let version = detail.metadata?.version {
                metadataRow(label: "Version", value: "v\(version)")
            }
            if let flags = detail.metadata?.flags {
                metadataRow(label: "Flags", value: "0x\(String(flags, radix: 16, uppercase: true))")
            }
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        GridRow {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
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
        .accessibilityLabel(annotationSession.isSelectedNodeBookmarked ? "Remove bookmark" : "Add bookmark")
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.bookmarkButton)
    }

    @ViewBuilder
    private func fieldAnnotationSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Fields", icon: "list.bullet.rectangle")
            if let error = viewModel.annotationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            if viewModel.annotations.isEmpty && viewModel.annotationError == nil {
                Text("No field annotations available for this selection.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
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
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Notes", icon: "note.text")
            if !annotationSession.isStoreAvailable {
                Text("Notes are unavailable on this platform.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !annotationSession.isEnabled || selectedNodeID == nil {
                Text("Select a box in a parsed file to add notes and bookmarks.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                if let message = annotationSession.lastErrorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if annotationSession.activeAnnotations.isEmpty {
                    Text("No notes yet. Add your first note below.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
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
        VStack(alignment: .leading, spacing: 6) {
            Text("Add note")
                .font(.caption)
                .foregroundStyle(.secondary)
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
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(annotation.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(annotation.formattedRange)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(annotation.value)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                if let summary = annotation.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.06))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 1 : 0.5)
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
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Validation", icon: "checkmark.shield")
            if detail.validationIssues.isEmpty {
                Text("No validation issues detected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(detail.validationIssues.enumerated()), id: \.offset) { _, issue in
                        validationRow(issue: issue)
                    }
                }
            }
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.validation)
    }

    private func validationRow(issue: ValidationIssue) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                SeverityBadge(severity: issue.severity)
                Text(issue.ruleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .padding(8)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(issue.ruleID). \(issue.severity.accessibilityDescription). \(issue.message)")
    }

    private func hexSection(detail: ParseTreeNodeDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Hex", icon: "rectangle.grid.1x2")
            if let error = viewModel.hexError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            if let slice = detail.hexSlice, !slice.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Offsets \(slice.offset) – \(slice.endOffset)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    .foregroundStyle(.secondary)
            }
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.hexView)
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
        }
    }

    private func byteRangeString(for range: Range<Int64>) -> String {
        "\(range.lowerBound) – \(range.upperBound)"
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
                LazyVStack(alignment: .leading, spacing: 6) {
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
                .padding(8)
            }
            .frame(minHeight: 200, idealHeight: 240, maxHeight: 320)
            .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onChange(of: highlightedRange) { _, newValue in
                guard let range = newValue, let id = rowID(for: range) else { return }
                DispatchQueue.main.async {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
            .focused(focusTarget, equals: .hex)
            .focusable(true)
            .onAppear {
                focusedOffset = highlightedRange?.lowerBound
            }
            .onChange(of: highlightedRange) { _, newValue in
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
        Array(repeating: GridItem(.fixed(28), spacing: 4), count: bytesPerRow)
    }

    private let accessibilityFormatter = HexByteAccessibilityFormatter()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(String(format: "%08llX", UInt64(max(0, row.offset))))
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            LazyVGrid(columns: hexColumns, spacing: 4) {
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

    init(text: String, isHighlighted: Bool, width: CGFloat, accessibilityLabel: String, onTap: @escaping () -> Void) {
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
                .stroke(isHighlighted ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isHighlighted ? 1 : 0.5)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Updated " + record.updatedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.gray.opacity(0.08))
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.Notes.row(record.id))
        .onAppear {
            draft = record.note
        }
        .onChange(of: record.note) { _, newValue in
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
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(severity.color.opacity(0.2))
            .foregroundStyle(severity.color)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private extension ValidationIssue.Severity {
    var label: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }

    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
#endif

