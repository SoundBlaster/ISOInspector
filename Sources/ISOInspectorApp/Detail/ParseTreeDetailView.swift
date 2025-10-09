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
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Metadata", icon: "info.circle")
            metadataGrid(detail: detail)
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Offsets \(slice.offset) – \(slice.endOffset)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    // @todo PDD:1h #7 Highlight field subranges and support selection syncing once payload annotations are available.
                    ScrollView(.horizontal) {
                        Text(hexDump(for: slice))
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
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

    private func hexDump(for slice: HexSlice) -> String {
        let bytes = Array(slice.bytes)
        guard !bytes.isEmpty else { return "" }
        let asciiRange = 32...126
        var lines: [String] = []
        var offset = slice.offset
        var index = 0
        while index < bytes.count {
            let end = min(index + bytesPerRow, bytes.count)
            let chunk = bytes[index..<end]
            let hex = chunk.map { String(format: "%02X", $0) }.joined(separator: " ")
            let paddedHex = hex.padding(toLength: bytesPerRow * 3 - 1, withPad: " ", startingAt: 0)
            let ascii = chunk.map { byte -> String in
                asciiRange.contains(Int(byte)) ? String(UnicodeScalar(byte)) : "."
            }.joined()
            let paddedAscii = ascii.padding(toLength: bytesPerRow, withPad: " ", startingAt: 0)
            let line = String(format: "%08llX  %@  |%@|", UInt64(max(0, offset)), paddedHex, paddedAscii)
            lines.append(line)
            offset += Int64(end - index)
            index = end
        }
        return lines.joined(separator: "\n")
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
