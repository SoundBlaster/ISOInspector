import Combine
import SwiftUI
import NestedA11yIDs
import ISOInspectorKit
import FoundationUI

struct ParseTreeExplorerView: View {
    @ObservedObject var viewModel: DocumentViewModel
    @ObservedObject private var outlineViewModel: ParseTreeOutlineViewModel
    @ObservedObject private var annotations: AnnotationBookmarkSession
    @Binding var selectedNodeID: ParseTreeNode.ID?
    @Binding var showInspector: Bool
    let focusTarget: FocusState<InspectorFocusTarget?>.Binding
    let ensureIntegrityViewModel: () -> Void
    let toggleInspectorVisibility: () -> Void
    let exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)?
    let exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)?
    private let focusCatalog = InspectorFocusShortcutCatalog.default

    init(
        viewModel: DocumentViewModel,
        selectedNodeID: Binding<ParseTreeNode.ID?>,
        showInspector: Binding<Bool>,
        focusTarget: FocusState<InspectorFocusTarget?>.Binding,
        ensureIntegrityViewModel: @escaping () -> Void,
        toggleInspectorVisibility: @escaping () -> Void,
        exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)? = nil,
        exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)? = nil
    ) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._outlineViewModel = ObservedObject(wrappedValue: viewModel.outlineViewModel)
        self._annotations = ObservedObject(wrappedValue: viewModel.annotations)
        self._selectedNodeID = selectedNodeID
        self._showInspector = showInspector
        self.focusTarget = focusTarget
        self.ensureIntegrityViewModel = ensureIntegrityViewModel
        self.toggleInspectorVisibility = toggleInspectorVisibility
        self.exportSelectionJSONAction = exportSelectionJSONAction
        self.exportSelectionIssueSummaryAction = exportSelectionIssueSummaryAction
    }

    var body: some View {
//        VStack(alignment: .leading, spacing: DS.Spacing.l) {
        ScrollView {

            header

            explorerColumn
                .focused(focusTarget, equals: .outline)
                .padding(.horizontal, DS.Spacing.m)
                .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.root)
        }

        .onAppear {
            focusTarget.wrappedValue = .outline
            if showInspector {
                ensureIntegrityViewModel()
            }
        }
        .onChangeCompatibility(of: showInspector) { isShowingIntegrity in
            if isShowingIntegrity {
                ensureIntegrityViewModel()
            }
        }
        .background(focusCommands)
    }

    private var explorerColumn: some View {
        ParseTreeOutlineView(
            viewModel: outlineViewModel,
            selectedNodeID: $selectedNodeID,
            annotationSession: annotations,
            focusTarget: focusTarget,
            exportSelectionJSONAction: exportSelectionJSONAction,
            exportSelectionIssueSummaryAction: exportSelectionIssueSummaryAction
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(headerTitle)
                    .font(.title2)
                    .bold()
                    .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.title)

                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.subtitle)
            }

            Spacer()

            ParseStateBadge(state: viewModel.parseState)
                .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.parseState)
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.root)
        .padding(DS.Spacing.m)
    }

    private var headerTitle: String {
        "Box Hierarchy"
    }

    private var headerSubtitle: String {
        "Search, filter, and expand ISO BMFF boxes"
    }

    private var focusCommands: some View {
        Group {
            ForEach(focusCatalog.shortcuts) { descriptor in
                HiddenKeyboardShortcutButton(
                    title: LocalizedStringKey(descriptor.title),
                    key: keyEquivalent(for: descriptor),
                    modifiers: [.command, .option]
                ) {
                    focusTarget.wrappedValue = descriptor.target
                }
            }
            HiddenKeyboardShortcutButton(
                title: "Next Issue",
                key: "e",
                modifiers: [.command, .shift]
            ) {
                navigateToIssue(direction: .down)
            }
            HiddenKeyboardShortcutButton(
                title: "Previous Issue",
                key: "e",
                modifiers: [.command, .shift, .option]
            ) {
                navigateToIssue(direction: .up)
            }
            HiddenKeyboardShortcutButton(
                title: "Toggle Inspector Column",
                key: "i",
                modifiers: [.command, .option]
            ) {
                toggleInspectorVisibility()
            }
        }
    }

    private func keyEquivalent(for descriptor: InspectorFocusShortcutDescriptor) -> KeyEquivalent {
        KeyEquivalent(descriptor.key.first ?? " ")
    }

    private func navigateToIssue(direction: ParseTreeOutlineViewModel.NavigationDirection) {
        guard
            let targetID = outlineViewModel.issueRowID(
                after: selectedNodeID,
                direction: direction
            )
        else { return }
        outlineViewModel.revealNode(withID: targetID)
        focusTarget.wrappedValue = .outline
        selectedNodeID = targetID
    }
}
