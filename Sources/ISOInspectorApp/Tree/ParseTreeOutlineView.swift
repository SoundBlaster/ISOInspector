#if canImport(SwiftUI) && canImport(Combine)
  import Combine
  import SwiftUI
  import NestedA11yIDs
  import ISOInspectorKit
  import FoundationUI

  struct ParseTreeExplorerView: View {
    @ObservedObject var viewModel: DocumentViewModel
    @ObservedObject private var outlineViewModel: ParseTreeOutlineViewModel
    @ObservedObject private var detailViewModel: ParseTreeDetailViewModel
    @ObservedObject private var annotations: AnnotationBookmarkSession
    @ObservedObject private var parseTreeStore: ParseTreeStore
    @State private var displayMode = InspectorDisplayMode()
    @State private var inspectorVisibility = InspectorColumnVisibility()
    @State private var integrityViewModel: IntegritySummaryViewModel?
    @FocusState private var focusTarget: InspectorFocusTarget?
    let exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)?
    let exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)?
    let exportDocumentJSONAction: (@MainActor () -> Void)?
    let exportDocumentIssueSummaryAction: (@MainActor () -> Void)?
    private let focusCatalog = InspectorFocusShortcutCatalog.default

    init(
      viewModel: DocumentViewModel,
      exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)? = nil,
      exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)? = nil,
      exportDocumentJSONAction: (@MainActor () -> Void)? = nil,
      exportDocumentIssueSummaryAction: (@MainActor () -> Void)? = nil
    ) {
      self._viewModel = ObservedObject(wrappedValue: viewModel)
      self._outlineViewModel = ObservedObject(wrappedValue: viewModel.outlineViewModel)
      self._detailViewModel = ObservedObject(wrappedValue: viewModel.detailViewModel)
      self._annotations = ObservedObject(wrappedValue: viewModel.annotations)
      self._parseTreeStore = ObservedObject(wrappedValue: viewModel.store)
      self.exportSelectionJSONAction = exportSelectionJSONAction
      self.exportSelectionIssueSummaryAction = exportSelectionIssueSummaryAction
      self.exportDocumentJSONAction = exportDocumentJSONAction
      self.exportDocumentIssueSummaryAction = exportDocumentIssueSummaryAction
    }

    var body: some View {
      VStack(alignment: .leading, spacing: DS.Spacing.l) {
        header
        NavigationSplitView(columnVisibility: inspectorColumnVisibilityBinding) {
          explorerColumn
            .frame(minWidth: 320)
            .focused($focusTarget, equals: .outline)
            .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.root)
        } detail: {
          inspectorColumn
            .frame(minWidth: 360)
            .focused($focusTarget, equals: .detail)
        }
        .navigationSplitViewStyle(.balanced)
      }
      .padding()
      .onAppear {
        focusTarget = .outline
        ensureIntegrityViewModel()
      }
      .onChangeCompatibility(of: displayMode.isShowingIntegritySummary) { isShowingIntegrity in
        if isShowingIntegrity {
          ensureIntegrityViewModel()
        }
      }
      .background(focusCommands)
      .focusedSceneValue(\.inspectorFocusTarget, focusBinding)
    }

    private var explorerColumn: some View {
      ParseTreeOutlineView(
        viewModel: outlineViewModel,
        selectedNodeID: selectionBinding,
        annotationSession: annotations,
        focusTarget: $focusTarget,
        exportSelectionJSONAction: exportSelectionJSONAction,
        exportSelectionIssueSummaryAction: exportSelectionIssueSummaryAction
      )
    }

    private var inspectorColumn: some View {
      InspectorDetailView(
        detailViewModel: detailViewModel,
        annotationSession: annotations,
        selectedNodeID: selectionBinding,
        integrityViewModel: integrityViewModel,
        showsIntegritySummary: displayMode.isShowingIntegritySummary,
        exportDocumentJSONAction: exportDocumentJSONAction,
        exportDocumentIssueSummaryAction: exportDocumentIssueSummaryAction,
        onIssueSelected: handleIssueSelected,
        focusTarget: $focusTarget
      )
      .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Inspector.root)
    }

    private func handleIssueSelected(_ issue: ParseIssue) {
      guard let nodeID = issue.affectedNodeIDs.first else { return }
      outlineViewModel.revealNode(withID: nodeID)
      viewModel.nodeViewModel.select(nodeID: nodeID)
      inspectorVisibility.ensureInspectorVisible()
      displayMode.current = .selectionDetails
      focusTarget = .outline
    }

    private func ensureIntegrityViewModel() {
      if integrityViewModel == nil {
        integrityViewModel = IntegritySummaryViewModel(issueStore: parseTreeStore.issueStore)
      }
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
        Button {
          toggleInspectorMode()
        } label: {
          Label(displayMode.toggleButtonLabel, systemImage: inspectorToggleIconName)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel(inspectorToggleAccessibilityLabel)
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.inspectorToggle)
        ParseStateBadge(state: viewModel.parseState)
          .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.parseState)
      }
      .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.root)
    }

    private var headerTitle: String {
      displayMode.isShowingIntegritySummary ? "Integrity Report" : "Box Hierarchy"
    }

    private var headerSubtitle: String {
      displayMode.isShowingIntegritySummary
        ? "Review and triage parsing issues"
        : "Search, filter, and expand ISO BMFF boxes"
    }

    private var focusCommands: some View {
      Group {
        ForEach(focusCatalog.shortcuts) { descriptor in
          HiddenKeyboardShortcutButton(
            title: LocalizedStringKey(descriptor.title),
            key: keyEquivalent(for: descriptor),
            modifiers: [.command, .option]
          ) {
            focusTarget = descriptor.target
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

    private var focusBinding: Binding<InspectorFocusTarget?> {
      Binding(
        get: { focusTarget },
        set: { focusTarget = $0 }
      )
    }

    private var inspectorToggleIconName: String {
      displayMode.isShowingIntegritySummary ? "checkmark.shield" : "info.circle"
    }

    private var inspectorToggleAccessibilityLabel: String {
      displayMode.isShowingIntegritySummary
        ? "Show Selection Details"
        : "Show Integrity Summary"
    }

    private func toggleInspectorMode() {
      inspectorVisibility.ensureInspectorVisible()
      displayMode.toggle()
      if displayMode.isShowingIntegritySummary {
        ensureIntegrityViewModel()
      }
    }

    private func toggleInspectorVisibility() {
      inspectorVisibility.toggleInspectorVisibility()
    }

    private func keyEquivalent(for descriptor: InspectorFocusShortcutDescriptor) -> KeyEquivalent {
      KeyEquivalent(descriptor.key.first ?? " ")
    }

    private var selectionBinding: Binding<ParseTreeNode.ID?> {
      Binding(
        get: { viewModel.nodeViewModel.selectedNodeID },
        set: { newValue in viewModel.nodeViewModel.select(nodeID: newValue) }
      )
    }

    private func navigateToIssue(direction: ParseTreeOutlineViewModel.NavigationDirection) {
      guard
        let targetID = outlineViewModel.issueRowID(
          after: viewModel.nodeViewModel.selectedNodeID,
          direction: direction
        )
      else { return }
      outlineViewModel.revealNode(withID: targetID)
      inspectorVisibility.ensureInspectorVisible()
      displayMode.current = .selectionDetails
      focusTarget = .outline
      viewModel.nodeViewModel.select(nodeID: targetID)
    }

    private var inspectorColumnVisibilityBinding: Binding<NavigationSplitViewVisibility> {
      Binding(
        get: { inspectorVisibility.columnVisibility },
        set: { inspectorVisibility.columnVisibility = $0 }
      )
    }
  }

  struct ParseTreeOutlineView: View {
    @ObservedObject var viewModel: ParseTreeOutlineViewModel
    @Binding var selectedNodeID: ParseTreeNode.ID?
    @ObservedObject var annotationSession: AnnotationBookmarkSession
    @FocusState private var focusedRowID: ParseTreeNode.ID?
    let focusTarget: FocusState<InspectorFocusTarget?>.Binding
    let exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)?
    let exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)?

    init(
      viewModel: ParseTreeOutlineViewModel,
      selectedNodeID: Binding<ParseTreeNode.ID?>,
      annotationSession: AnnotationBookmarkSession,
      focusTarget: FocusState<InspectorFocusTarget?>.Binding,
      exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)? = nil,
      exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)? = nil
    ) {
      self._viewModel = ObservedObject(wrappedValue: viewModel)
      self._selectedNodeID = selectedNodeID
      self._annotationSession = ObservedObject(wrappedValue: annotationSession)
      self.focusTarget = focusTarget
      self.exportSelectionJSONAction = exportSelectionJSONAction
      self.exportSelectionIssueSummaryAction = exportSelectionIssueSummaryAction
    }
    @State private var keyboardSelectionID: ParseTreeNode.ID?

    var body: some View {
      VStack(spacing: DS.Spacing.m) {
        searchBar
        severityFilterBar
        if !viewModel.availableCategories.isEmpty {
          categoryFilterBar
        }
        if viewModel.containsStreamingIndicators {
          streamingToggle
        }
        outlineList
      }
      .onAppear {
        keyboardSelectionID = selectedNodeID
        focusedRowID = selectedNodeID
      }
      .onChangeCompatibility(of: selectedNodeID) { newValue in
        keyboardSelectionID = newValue
        focusedRowID = newValue
      }
    }

    private var searchBar: some View {
      TextField("Search boxes, names, or summaries", text: $viewModel.searchText)
        .textFieldStyle(.roundedBorder)
        .focused(focusTarget, equals: .outline)
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.searchField)
    }

    private var severityFilterBar: some View {
      HStack(spacing: DS.Spacing.s) {
        ForEach(ValidationIssue.Severity.allCases, id: \.self) { severity in
          Toggle(isOn: binding(for: severity)) {
            Text(severity.label)
              .font(.caption)
              .padding(.horizontal, DS.Spacing.s)
              .padding(.vertical, DS.Spacing.xxs)
              .background(filterBackground(for: severity))
              .foregroundColor(filterForeground(for: severity))
              .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
          }
          .toggleStyle(.button)
          .nestedAccessibilityIdentifier(
            ParseTreeAccessibilityID.Outline.Filters.severityToggle(severity))
        }
        Toggle(isOn: bindingForIssuesOnly) {
          Label("Issues only", systemImage: issuesToggleIconName)
            .font(.caption)
            .padding(.horizontal, DS.Spacing.m - 2)
            .padding(.vertical, DS.Spacing.xxs)
            .background(issuesToggleBackground)
            .foregroundColor(issuesToggleForeground)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
        }
        .toggleStyle(.button)
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.issuesOnlyToggle)
        Spacer()
        if viewModel.filter.isFocused {
          Button("Clear filters") {
            viewModel.filter = .all
          }
          .font(.caption)
          .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.clearButton)
        }
      }
    }

    private var categoryFilterBar: some View {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: DS.Spacing.s) {
          ForEach(viewModel.availableCategories, id: \.self) { category in
            Toggle(isOn: binding(for: category)) {
              Text(category.label)
                .font(.caption)
                .padding(.horizontal, DS.Spacing.s)
                .padding(.vertical, DS.Spacing.xxs)
                .background(categoryBackground(for: category))
                .foregroundColor(categoryForeground(for: category))
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
            }
            .toggleStyle(.button)
            .nestedAccessibilityIdentifier(
              ParseTreeAccessibilityID.Outline.Filters.categoryToggle(category))
          }
        }
      }
    }

    private var streamingToggle: some View {
      Toggle(isOn: bindingForStreamingIndicators) {
        Label("Show streaming markers", systemImage: "dot.radiowaves.left.and.right")
          .font(.caption)
      }
      .toggleStyle(.switch)
      .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.streamingToggle)
    }

    @ViewBuilder
    private var outlineList: some View {
      if viewModel.rows.isEmpty {
        emptyStateView
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.rows) { row in
              ParseTreeOutlineRowView(
                row: row,
                isSelected: selectedNodeID == row.id,
                isBookmarked: annotationSession.isBookmarked(nodeID: row.id),
                isBookmarkingEnabled: annotationSession.isEnabled,
                onSelect: {
                  selectedNodeID = row.id
                  if !row.node.children.isEmpty {
                    viewModel.toggleExpansion(for: row.id)
                  }
                  keyboardSelectionID = row.id
                },
                onToggleBookmark: {
                  selectedNodeID = row.id
                  annotationSession.setSelectedNode(row.id)
                  annotationSession.toggleBookmark()
                },
                onExportJSON: exportSelectionJSONAction.map { action in
                  { @MainActor in action(row.id) }
                },
                onExportIssueSummary: exportSelectionIssueSummaryAction.map { action in
                  { @MainActor in action(row.id) }
                }
              )
              .id(row.id)
              .focused($focusedRowID, equals: row.id)
              .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.row(row.id))
              .compatibilityFocusable()
              .onTapGesture {
                focusTarget.wrappedValue = .outline
                focusedRowID = row.id
              }
            }
          }
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.root)
        #if !os(iOS)
          .onMoveCommand { direction in
            guard focusTarget.wrappedValue == .outline else { return }
            guard let nextID = nextRowID(for: direction) else { return }
            if nextID != selectedNodeID {
              selectedNodeID = nextID
            }
            keyboardSelectionID = nextID
            focusedRowID = nextID
          }
        #endif
      }
    }

    @ViewBuilder
    private var emptyStateView: some View {
      if #available(iOS 17, macOS 14, *) {
        ContentUnavailableView(
          "No boxes",
          systemImage: "tray",
          description: Text("Run a parse to populate the hierarchy or adjust filters.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.emptyState)
      } else {
        VStack(spacing: DS.Spacing.m) {
          Image(systemName: "tray")
            .font(.system(size: 44))
            .foregroundColor(.secondary)
          Text("No boxes")
            .font(.headline)
          Text("Run a parse to populate the hierarchy or adjust filters.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.emptyState)
      }
    }

    private func binding(for severity: ValidationIssue.Severity) -> Binding<Bool> {
      Binding(
        get: { viewModel.filter.focusedSeverities.contains(severity) },
        set: { viewModel.setSeverity(severity, isEnabled: $0) }
      )
    }

    private func binding(for category: BoxCategory) -> Binding<Bool> {
      Binding(
        get: { viewModel.filter.focusedCategories.contains(category) },
        set: { viewModel.setCategory(category, isEnabled: $0) }
      )
    }

    private var bindingForStreamingIndicators: Binding<Bool> {
      Binding(
        get: { viewModel.filter.showsStreamingIndicators },
        set: { viewModel.setShowsStreamingIndicators($0) }
      )
    }

    private var bindingForIssuesOnly: Binding<Bool> {
      Binding(
        get: { viewModel.filter.showsOnlyIssues },
        set: { newValue in
          var updated = viewModel.filter
          updated.showsOnlyIssues = newValue
          viewModel.filter = updated
        }
      )
    }

    private func filterBackground(for severity: ValidationIssue.Severity) -> Color {
      let isActive = viewModel.filter.focusedSeverities.contains(severity)
      return severity.color.opacity(isActive ? 0.25 : 0.08)
    }

    private func filterForeground(for severity: ValidationIssue.Severity) -> Color {
      let isActive = viewModel.filter.focusedSeverities.contains(severity)
      return isActive ? severity.color : .secondary
    }

    private func categoryBackground(for category: BoxCategory) -> Color {
      let isActive = viewModel.filter.focusedCategories.contains(category)
      return category.color.opacity(isActive ? 0.25 : 0.08)
    }

    private func categoryForeground(for category: BoxCategory) -> Color {
      let isActive = viewModel.filter.focusedCategories.contains(category)
      return isActive ? category.color : .secondary
    }

    private var issuesToggleBackground: Color {
      Color.accentColor.opacity(viewModel.filter.showsOnlyIssues ? 0.25 : 0.08)
    }

    private var issuesToggleForeground: Color {
      viewModel.filter.showsOnlyIssues ? Color.accentColor : .secondary
    }

    private var issuesToggleIconName: String {
      viewModel.filter.showsOnlyIssues
        ? "exclamationmark.triangle.fill" : "exclamationmark.triangle"
    }

    #if !os(iOS)
      private func nextRowID(for direction: MoveCommandDirection) -> ParseTreeNode.ID? {
        let activeID = keyboardSelectionID ?? selectedNodeID
        switch direction {
        case .down:
          return viewModel.rowID(after: activeID, direction: .down)
        case .up:
          return viewModel.rowID(after: activeID, direction: .up)
        case .left:
          guard let activeID else { return nil }
          if let row = viewModel.rows.first(where: { $0.id == activeID }), row.isExpanded {
            viewModel.toggleExpansion(for: activeID)
            return activeID
          }
          return viewModel.rowID(after: activeID, direction: .parent) ?? activeID
        case .right:
          guard let activeID else { return nil }
          guard let row = viewModel.rows.first(where: { $0.id == activeID }) else {
            return activeID
          }
          if row.node.children.isEmpty {
            return activeID
          }
          if !row.isExpanded {
            viewModel.toggleExpansion(for: activeID)
          }
          return viewModel.rowID(after: activeID, direction: .child) ?? activeID
        default:
          return activeID
        }
      }
    #endif
  }

  private struct ParseTreeOutlineRowView: View {
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
        VStack(alignment: .leading, spacing: 2) {  // @todo #I1.5 Replace spacing: 2 with DS token when xxxs (2pt) is added
          Text(row.displayName)
            .font(.body)
            .fontWeight(row.isSearchMatch ? .semibold : .regular)
            .foregroundColor(row.isSearchMatch ? Color.accentColor : Color.primary)
          Text(row.typeDescription)
            .font(.caption)
            .foregroundColor(.secondary)
          if let summary = row.summary, !summary.isEmpty {
            Text(summary)
              .font(.caption2)
              .foregroundColor(.secondary)
              .lineLimit(2)
          }
        }
        Spacer()
        if let statusDescriptor = row.statusDescriptor {
          HStack(spacing: DS.Spacing.s) {
            Indicator(
              level: descriptorBadgeLevel(statusDescriptor.level),
              size: .mini,
              reason: statusDescriptor.accessibilityLabel,
              tooltip: .text(statusDescriptor.text)
            )
            ParseTreeStatusBadge(descriptor: statusDescriptor)
          }
        }
        if let corruption = row.corruptionSummary {
          CorruptionBadge(summary: corruption)
        } else if let severity = row.dominantSeverity {
          SeverityBadge(severity: severity)
        } else if row.hasValidationIssues {
          SeverityBadge(severity: .info)
        }
        bookmarkButton
      }
      .padding(.vertical, DS.Spacing.xs)
      .padding(.leading, CGFloat(row.depth) * DS.Spacing.l + DS.Spacing.xxs)
      .padding(.trailing, DS.Spacing.s)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(background)
      .contentShape(Rectangle())
      .onTapGesture(perform: onSelect)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(accessibilityDescriptor.label)
      .accessibilityValue(optional: accessibilityDescriptor.value)
      .accessibilityHint(optional: accessibilityDescriptor.hint)
      .contextMenu {
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
          Image(systemName: "square")
            .foregroundColor(.secondary)
        } else {
          Image(systemName: row.isExpanded ? "chevron.down" : "chevron.right")
            .foregroundColor(.secondary)
        }
      }
      .frame(width: 12)
    }

    private var bookmarkButton: some View {
      Button(action: onToggleBookmark) {
        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
          .foregroundColor(isBookmarked ? Color.accentColor : Color.secondary)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
      .disabled(!isBookmarkingEnabled)
      .opacity(isBookmarkingEnabled ? 1 : 0.35)
      .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.rowBookmark(row.id))
    }

    private var background: some View {
      RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
        .fill(backgroundColor)
    }

    private var backgroundColor: Color {
      if isSelected {
        return Color.accentColor.opacity(0.18)
      }
      if row.isSearchMatch {
        return Color.accentColor.opacity(0.12)
      }
      return Color.clear
    }

    private var accessibilityDescriptor: AccessibilityDescriptor {
      row.accessibilityDescriptor(isBookmarked: isBookmarked)
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
  }

  private struct CorruptionBadge: View {
    let summary: ParseTreeOutlineRow.CorruptionSummary

    var body: some View {
      Badge(text: summary.badgeText, level: badgeLevel, showIcon: true)
        .help(summary.tooltipText ?? summary.badgeText)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary.accessibilityLabel)
        .accessibilityHint(optional: summary.accessibilityHint)
        #if os(macOS)
          .focusable(true)
        #endif
    }

    private var badgeLevel: BadgeLevel {
      switch summary.dominantSeverity {
      case .info:
        return .info
      case .warning:
        return .warning
      case .error:
        return .error
      }
    }
  }

  private struct SeverityBadge: View {
    let severity: ValidationIssue.Severity

    var body: some View {
      Badge(text: severity.label.uppercased(), level: badgeLevel)
    }

    private var badgeLevel: BadgeLevel {
      switch severity {
      case .info:
        return .info
      case .warning:
        return .warning
      case .error:
        return .error
      }
    }
  }

  private struct ParseStateBadge: View {
    let state: ParseTreeStoreState

    var body: some View {
      Badge(text: stateDescription, level: badgeLevel)
    }

    private var stateDescription: String {
      switch state {
      case .idle: return "Idle"
      case .parsing: return "Parsing"
      case .finished: return "Finished"
      case .failed(let message): return "Failed: \(message)"
      }
    }

    private var badgeLevel: BadgeLevel {
      switch state {
      case .idle: return .info
      case .parsing: return .info
      case .finished: return .success
      case .failed: return .error
      }
    }
  }

  extension ParseIssue.Severity {
    fileprivate var label: String {
      switch self {
      case .info: return "Info"
      case .warning: return "Warning"
      case .error: return "Error"
      }
    }

    fileprivate var color: Color {
      switch self {
      case .info: return .blue
      case .warning: return .orange
      case .error: return .red
      }
    }
  }

  extension ValidationIssue.Severity {
    fileprivate var label: String {
      switch self {
      case .info: return "Info"
      case .warning: return "Warning"
      case .error: return "Error"
      }
    }

    fileprivate var color: Color {
      switch self {
      case .info: return .blue
      case .warning: return .orange
      case .error: return .red
      }
    }
  }

  extension BoxCategory {
    fileprivate var label: String {
      switch self {
      case .metadata: return "Metadata"
      case .media: return "Media"
      case .index: return "Index"
      case .container: return "Container"
      case .other: return "Other"
      }
    }

    fileprivate var color: Color {
      switch self {
      case .metadata: return .purple
      case .media: return .green
      case .index: return .blue
      case .container: return .teal
      case .other: return .gray
      }
    }
  }

  #Preview("Outline View") {
    ParseTreeOutlinePreview()
  }

  #Preview("Explorer") {
    ParseTreeExplorerPreview()
  }

  private struct ParseTreeOutlinePreview: View {
    @StateObject private var viewModel: ParseTreeOutlineViewModel
    @StateObject private var annotations = AnnotationBookmarkSession(store: nil)
    @State private var selectedNodeID: ParseTreeNode.ID?
    @FocusState private var focusTarget: InspectorFocusTarget?

    init() {
      let model = ParseTreeOutlineViewModel()
      model.apply(snapshot: ParseTreePreviewData.sampleSnapshot)
      _viewModel = StateObject(wrappedValue: model)
      _selectedNodeID = State(initialValue: ParseTreePreviewData.sampleSnapshot.nodes.first?.id)
    }

    var body: some View {
      ParseTreeOutlineView(
        viewModel: viewModel,
        selectedNodeID: $selectedNodeID,
        annotationSession: annotations,
        focusTarget: $focusTarget
      )
      .frame(width: 420, height: 480)
    }
  }

  private struct ParseTreeExplorerPreview: View {
    @StateObject private var documentViewModel: DocumentViewModel

    init() {
      let snapshot = ParseTreePreviewData.sampleSnapshot
      let store = ParseTreeStore(initialSnapshot: snapshot, initialState: .finished)
      let annotations = AnnotationBookmarkSession(store: nil)
      _documentViewModel = StateObject(
        wrappedValue: DocumentViewModel(store: store, annotations: annotations))
    }

    var body: some View {
      ParseTreeExplorerView(
        viewModel: documentViewModel
      )
      .frame(width: 760, height: 520)
    }
  }

  extension View {
    @ViewBuilder
    fileprivate func accessibilityValue(optional value: String?) -> some View {
      if let value {
        accessibilityValue(value)
      } else {
        self
      }
    }

    @ViewBuilder
    fileprivate func accessibilityHint(optional hint: String?) -> some View {
      if let hint {
        accessibilityHint(hint)
      } else {
        self
      }
    }

    @ViewBuilder
    fileprivate func compatibilityFocusable() -> some View {
      #if os(iOS)
        if #available(iOS 17, *) {
          focusable(true)
        } else {
          self
        }
      #else
        focusable(true)
      #endif
    }

    @ViewBuilder
    fileprivate func onChangeCompatibility<Value: Equatable>(
      of value: Value,
      initial: Bool = false,
      perform: @escaping (Value) -> Void
    ) -> some View {
      if #available(iOS 17, macOS 14, *) {
        onChange(of: value, initial: initial) { _, newValue in
          perform(newValue)
        }
      } else {
        onChange(of: value, perform: perform)
      }
    }
  }

  private struct HiddenKeyboardShortcutButton: View {
    let title: LocalizedStringKey
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let action: () -> Void

    var body: some View {
      Button(title) { action() }
        .keyboardShortcut(key, modifiers: modifiers)
        .buttonStyle(.plain)
        .frame(width: 0, height: 0)
        .opacity(0.001)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }
#endif
