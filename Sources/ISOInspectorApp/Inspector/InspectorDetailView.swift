#if canImport(SwiftUI) && canImport(Combine)
  import SwiftUI
  import ISOInspectorKit
  import NestedA11yIDs
  import FoundationUI

  struct InspectorDetailView: View {
    @ObservedObject var detailViewModel: ParseTreeDetailViewModel
    @ObservedObject var annotationSession: AnnotationBookmarkSession
    @Binding var selectedNodeID: ParseTreeNode.ID?
    let integrityViewModel: IntegritySummaryViewModel?
    let showsIntegritySummary: Bool
    let exportDocumentJSONAction: (@MainActor () -> Void)?
    let exportDocumentIssueSummaryAction: (@MainActor () -> Void)?
    let onIssueSelected: (ParseIssue) -> Void
    let focusTarget: FocusState<InspectorFocusTarget?>.Binding

    var body: some View {
      Group {
        if showsIntegritySummary {
          integrityContent
        } else {
          selectionDetailsContent
        }
      }
      .padding(.horizontal, DS.Spacing.m)
      .padding(.vertical, DS.Spacing.m)
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // @todo #243 Split Selection Details into dedicated inspector subviews (metadata, corruption,
    //   encryption, notes, fields, validation, hex) so the inspector column can scroll more
    //   predictably and align with DOCS/INPROGRESS/243_Reorganize_Navigation_SplitView_Inspector_Panel.md.
    private var selectionDetailsContent: some View {
      ParseTreeDetailView(
        viewModel: detailViewModel,
        annotationSession: annotationSession,
        selectedNodeID: $selectedNodeID,
        focusTarget: focusTarget
      )
      .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.root)
    }

    @ViewBuilder
    private var integrityContent: some View {
      if let integrityViewModel {
        IntegritySummaryView(
          viewModel: integrityViewModel,
          onIssueSelected: onIssueSelected,
          onExportJSON: exportDocumentJSONAction,
          onExportIssueSummary: exportDocumentIssueSummaryAction
        )
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Inspector.integritySummary)
      } else {
        VStack(alignment: .leading, spacing: 8) {
          ProgressView()
          Text("Loading integrity summary…")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Inspector.integritySummary)
      }
    }
  }
#endif
