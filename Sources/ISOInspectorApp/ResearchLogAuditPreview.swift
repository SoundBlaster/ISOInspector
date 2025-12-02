#if canImport(SwiftUI)
    import SwiftUI
    import NestedA11yIDs
    import ISOInspectorKit
    import FoundationUI
    #if os(macOS)
        import AppKit
    #endif

    struct ResearchLogAuditPreview: View {
        let snapshot: ResearchLogPreviewSnapshot

        var body: some View {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                header
                Divider()
                diagnosticsList
            }.padding(DS.Spacing.l).background(
                RoundedRectangle(cornerRadius: 2 * DS.Radius.medium, style: .continuous).fill(
                    containerBackgroundColor)
            ).overlay(
                RoundedRectangle(cornerRadius: 2 * DS.Radius.medium, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            ).padding().a11yRoot(ResearchLogAccessibilityID.root)
        }

        @ViewBuilder private var header: some View {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("VR-006 Research Log Audit").font(.title2).fontWeight(.semibold)
                    .nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.title)
                statusContent.nestedAccessibilityIdentifier(
                    ResearchLogAccessibilityID.Header.Status.root)
            }.nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.root)
        }

        @ViewBuilder private var statusContent: some View {
            switch snapshot.state {
            case .ready(let audit):
                readyHeader(for: audit).nestedAccessibilityIdentifier(
                    ResearchLogAccessibilityID.Header.Status.ready)
            case .missingFixture(let audit):
                missingHeader(for: audit).nestedAccessibilityIdentifier(
                    ResearchLogAccessibilityID.Header.Status.missingFixture)
            case .schemaMismatch(let expected, let actual):
                schemaMismatchHeader(expected: expected, actual: actual)
                    .nestedAccessibilityIdentifier(
                        ResearchLogAccessibilityID.Header.Status.schemaMismatch)
            case .loadFailure(let message):
                loadFailureHeader(message: message).nestedAccessibilityIdentifier(
                    ResearchLogAccessibilityID.Header.Status.loadFailure)
            }
        }

        @ViewBuilder private func readyHeader(for audit: ResearchLogAudit) -> some View {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Fixture \(snapshot.fixtureName) matches ResearchLogSchema.fieldNames.").font(
                    .callout
                ).foregroundColor(.secondary)
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                    GridRow {
                        Text("Schema").gridColumnAlignment(.leading).font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("v\(audit.schemaVersion)").font(.subheadline)
                    }.nestedAccessibilityIdentifier(
                        ResearchLogAccessibilityID.Header.Metadata.schemaVersion)
                    GridRow {
                        Text("Entries").font(.subheadline).foregroundColor(.secondary)
                        Text("\(audit.entryCount)").font(.subheadline.weight(.medium))
                    }.nestedAccessibilityIdentifier(
                        ResearchLogAccessibilityID.Header.Metadata.entryCount)
                    GridRow {
                        Text("Fields").font(.subheadline).foregroundColor(.secondary)
                        Text(audit.fieldNames.joined(separator: ", ")).font(.subheadline)
                    }.nestedAccessibilityIdentifier(
                        ResearchLogAccessibilityID.Header.Metadata.fieldNames)
                }.nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Header.Metadata.root)
            }
        }

        @ViewBuilder private func missingHeader(for audit: ResearchLogAudit) -> some View {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Missing preview fixture \(snapshot.fixtureName)").font(.headline)
                    .foregroundColor(.orange)
                Text(
                    "The shared VR-006 schema v\(audit.schemaVersion) expects fields: \(audit.fieldNames.joined(separator: ", "))."
                ).font(.callout).foregroundColor(.secondary).nestedAccessibilityIdentifier(
                    ResearchLogAccessibilityID.Header.MissingFixture.details)
            }
        }

        @ViewBuilder private func schemaMismatchHeader(expected: [String], actual: [String])
            -> some View
        {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Schema mismatch detected").font(.headline).foregroundColor(.red)
                Text("Expected: \(expected.joined(separator: ", "))").font(.callout)
                    .foregroundColor(.secondary).nestedAccessibilityIdentifier(
                        ResearchLogAccessibilityID.Header.SchemaMismatch.expected)
                Text("Actual: \(actual.joined(separator: ", "))").font(.callout).foregroundColor(
                    .red
                ).nestedAccessibilityIdentifier(
                    ResearchLogAccessibilityID.Header.SchemaMismatch.actual)
            }
        }

        @ViewBuilder private func loadFailureHeader(message: String) -> some View {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Failed to load \(snapshot.fixtureName)").font(.headline).foregroundColor(.red)
                Text(message).font(.callout).foregroundColor(.secondary)
                    .nestedAccessibilityIdentifier(
                        ResearchLogAccessibilityID.Header.LoadFailure.message)
            }
        }

        @ViewBuilder private var diagnosticsList: some View {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                ForEach(Array(snapshot.diagnostics.enumerated()), id: \.offset) { element in
                    Label {
                        Text(element.element).font(.footnote).foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "checkmark.seal").foregroundColor(.secondary)
                    }.nestedAccessibilityIdentifier(
                        ResearchLogAccessibilityID.Diagnostics.row(element.offset))
                }
            }.nestedAccessibilityIdentifier(ResearchLogAccessibilityID.Diagnostics.root)
        }

        private var borderColor: Color {
            switch snapshot.state {
            case .ready: return .green.opacity(0.45)
            case .missingFixture: return .orange.opacity(0.55)
            case .schemaMismatch, .loadFailure: return .red.opacity(0.65)
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

    #if compiler(>=5.9) && (os(iOS) || os(macOS) || os(tvOS))

        @available(iOS 17.0, macOS 14.0, tvOS 17.0, *) #Preview(
            "VR-006 Fixture Ready", traits: .sizeThatFitsLayout) {
                ResearchLogAuditPreview(snapshot: ResearchLogPreviewProvider.validFixture())
            }

        @available(iOS 17.0, macOS 14.0, tvOS 17.0, *) #Preview(
            "VR-006 Fixture Missing", traits: .sizeThatFitsLayout) {
                ResearchLogAuditPreview(snapshot: ResearchLogPreviewProvider.missingFixture())
            }

        @available(iOS 17.0, macOS 14.0, tvOS 17.0, *) #Preview(
            "VR-006 Schema Drift", traits: .sizeThatFitsLayout) {
                ResearchLogAuditPreview(
                    snapshot: ResearchLogPreviewProvider.schemaMismatchFixture())
            }
    #endif

#endif
