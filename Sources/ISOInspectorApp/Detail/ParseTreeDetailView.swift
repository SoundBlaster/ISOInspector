#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import ISOInspectorKit

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

struct ParseTreeDetailView: View {
    @ObservedObject var viewModel: ParseTreeDetailViewModel
    private let bytesPerRow = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
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
                    validationSection(detail: detail)
                    hexSection(detail: detail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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
            sectionHeader(title: "Metadata", icon: "info.circle")
            metadataGrid(detail: detail)
            annotationSection()
            Text("Snapshot updated ") + Text(detail.snapshotTimestamp, style: .relative)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
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

    @ViewBuilder
    private func annotationSection() -> some View {
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
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                        onSelectOffset: { viewModel.selectByte(at: $0) }
                    )
                }
            } else {
                Text("No payload bytes available for this selection.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
    let onSelectOffset: (Int64) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.vertical, .horizontal]) {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(rows) { row in
                        HexSliceRowView(
                            row: row,
                            bytesPerRow: bytesPerRow,
                            highlightedRange: highlightedRange,
                            onSelectOffset: onSelectOffset
                        )
                        .id(row.index)
                    }
                }
                .padding(8)
            }
            .frame(minHeight: 200, idealHeight: 240, maxHeight: 320)
            .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onChange(of: highlightedRange) { range in
                guard let range, let id = rowID(for: range) else { return }
                DispatchQueue.main.async {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
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
    let onSelectOffset: (Int64) -> Void

    private var hexColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(28), spacing: 4), count: bytesPerRow)
    }

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
                        HexByteCell(
                            text: String(format: "%02X", row.bytes[index]),
                            isHighlighted: isHighlighted(globalOffset),
                            width: 28
                        ) {
                            onSelectOffset(globalOffset)
                        }
                        .accessibilityLabel("Byte 0x\(String(format: "%02X", row.bytes[index])) at offset \(globalOffset)")
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
                            width: 16
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
    let onTap: () -> Void

    init(text: String, isHighlighted: Bool, width: CGFloat, onTap: @escaping () -> Void) {
        self.text = text
        self.isHighlighted = isHighlighted
        self.width = width
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
