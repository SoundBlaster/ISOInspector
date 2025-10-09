#if canImport(SwiftUI)
import SwiftUI
import ISOInspectorKit
#if os(macOS)
import AppKit
#endif

struct ResearchLogAuditPreview: View {
    let snapshot: ResearchLogPreviewSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                ForEach(snapshot.diagnostics, id: \.self) { diagnostic in
                    Label {
                        Text(diagnostic)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "checkmark.seal")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(containerBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .padding()
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VR-006 Research Log Audit")
                .font(.title2)
                .fontWeight(.semibold)
            switch snapshot.state {
            case let .ready(audit):
                readyHeader(for: audit)
            case let .missingFixture(audit):
                missingHeader(for: audit)
            case let .schemaMismatch(expected, actual):
                schemaMismatchHeader(expected: expected, actual: actual)
            case let .loadFailure(message):
                loadFailureHeader(message: message)
            }
        }
    }

    @ViewBuilder
    private func readyHeader(for audit: ResearchLogAudit) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Fixture \(snapshot.fixtureName) matches ResearchLogSchema.fieldNames.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                GridRow {
                    Text("Schema")
                        .gridColumnAlignment(.leading)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("v\(audit.schemaVersion)")
                        .font(.subheadline)
                }
                GridRow {
                    Text("Entries")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(audit.entryCount)")
                        .font(.subheadline.weight(.medium))
                }
                GridRow {
                    Text("Fields")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(audit.fieldNames.joined(separator: ", "))
                        .font(.subheadline)
                }
            }
        }
    }

    @ViewBuilder
    private func missingHeader(for audit: ResearchLogAudit) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Missing preview fixture \(snapshot.fixtureName)")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("The shared VR-006 schema v\(audit.schemaVersion) expects fields: \(audit.fieldNames.joined(separator: ", ")).")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func schemaMismatchHeader(expected: [String], actual: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Schema mismatch detected")
                .font(.headline)
                .foregroundStyle(.red)
            Text("Expected: \(expected.joined(separator: ", "))")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Actual: \(actual.joined(separator: ", "))")
                .font(.callout)
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private func loadFailureHeader(message: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Failed to load \(snapshot.fixtureName)")
                .font(.headline)
                .foregroundStyle(.red)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var borderColor: Color {
        switch snapshot.state {
        case .ready:
            return .green.opacity(0.45)
        case .missingFixture:
            return .orange.opacity(0.55)
        case .schemaMismatch, .loadFailure:
            return .red.opacity(0.65)
        }
    }

    private var containerBackgroundColor: Color {
#if os(macOS)
        Color(nsColor: NSColor.windowBackgroundColor)
#else
        Color(.secondarySystemBackground)
#endif
    }
}

#Preview("VR-006 Fixture Ready", traits: .sizeThatFitsLayout) {
    ResearchLogAuditPreview(snapshot: ResearchLogPreviewProvider.validFixture())
}

#Preview("VR-006 Fixture Missing", traits: .sizeThatFitsLayout) {
    ResearchLogAuditPreview(snapshot: ResearchLogPreviewProvider.missingFixture())
}

#Preview("VR-006 Schema Drift", traits: .sizeThatFitsLayout) {
    ResearchLogAuditPreview(snapshot: ResearchLogPreviewProvider.schemaMismatchFixture())
}
#endif
