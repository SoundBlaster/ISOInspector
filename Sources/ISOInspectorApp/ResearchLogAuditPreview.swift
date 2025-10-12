#if canImport(SwiftUI)
import SwiftUI
import ISOInspectorKit
import NestedA11yIDs
#if os(macOS)
import AppKit
#endif

struct ResearchLogAuditPreview: View {
    let snapshot: ResearchLogPreviewSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            diagnosticsList
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
        .a11yRoot(ResearchLogAccessibilityID.root)
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VR-006 Research Log Audit")
                .font(.title2)
                .fontWeight(.semibold)
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.title)
            statusContent
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.Status.root)
        }
        .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.root)
    }

    @ViewBuilder
    private var statusContent: some View {
        switch snapshot.state {
        case let .ready(audit):
            readyHeader(for: audit)
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.Status.ready)
        case let .missingFixture(audit):
            missingHeader(for: audit)
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.Status.missingFixture)
        case let .schemaMismatch(expected, actual):
            schemaMismatchHeader(expected: expected, actual: actual)
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.Status.schemaMismatch)
        case let .loadFailure(message):
            loadFailureHeader(message: message)
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.Status.loadFailure)
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
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.Metadata.schemaVersion)
                GridRow {
                    Text("Entries")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(audit.entryCount)")
                        .font(.subheadline.weight(.medium))
                }
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.Metadata.entryCount)
                GridRow {
                    Text("Fields")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(audit.fieldNames.joined(separator: ", "))
                        .font(.subheadline)
                }
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.Metadata.fieldNames)
            }
            .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.Metadata.root)
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
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.MissingFixture.details)
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
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.SchemaMismatch.expected)
            Text("Actual: \(actual.joined(separator: ", "))")
                .font(.callout)
                .foregroundStyle(.red)
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.SchemaMismatch.actual)
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
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.LoadFailure.message)
        }
    }

    @ViewBuilder
    private var diagnosticsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(snapshot.diagnostics.enumerated()), id: \.offset) { element in
                Label {
                    Text(element.element)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "checkmark.seal")
                        .foregroundStyle(.secondary)
                }
                .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Diagnostics.row(element.offset))
            }
        }
        .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Diagnostics.root)
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
