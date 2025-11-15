#if canImport(Combine)
  import Combine
  import Foundation
  import ISOInspectorKit
  #if canImport(os)
    import os
  #endif

  @MainActor
  final class ParseTreeOutlineViewModel: ObservableObject {
    @Published private(set) var rows: [ParseTreeOutlineRow] = []
    @Published private(set) var availableCategories: [BoxCategory] = []
    @Published private(set) var containsStreamingIndicators: Bool = false
    @Published var searchText: String = "" {
      didSet { rebuildRows() }
    }
    @Published var filter: ParseTreeOutlineFilter = .all {
      didSet { rebuildRows() }
    }

    enum NavigationDirection {
      case up
      case down
      case parent
      case child
    }

    private var snapshot: ParseTreeSnapshot = .empty
    private var expandedIdentifiers: Set<ParseTreeNode.ID> = []
    private var cancellables: Set<AnyCancellable> = []
    private var latencyProbe = OutlineLatencyProbe()
    private var allIdentifiers: Set<ParseTreeNode.ID> = []
    private var parentLookup: [ParseTreeNode.ID: ParseTreeNode.ID] = [:]
    private var issueBranchIdentifiers: Set<ParseTreeNode.ID> = []

    init(snapshot: ParseTreeSnapshot = .empty) {
      apply(snapshot: snapshot)
    }

    func bind<P: Publisher>(to publisher: P)
    where P.Output == ParseTreeSnapshot, P.Failure == Never {
      cancellables.forEach { $0.cancel() }
      cancellables.removeAll()
      publisher
        .sink { [weak self] snapshot in
          guard let self else { return }
          Task { @MainActor [weak self] in
            self?.apply(snapshot: snapshot)
          }
        }
        .store(in: &cancellables)
    }

    func apply(snapshot: ParseTreeSnapshot) {
      self.snapshot = snapshot
      allIdentifiers = collectIdentifiers(from: snapshot.nodes)
      if expandedIdentifiers.isEmpty {
        expandedIdentifiers.formUnion(snapshot.nodes.map(\.id))
      } else {
        expandedIdentifiers.formIntersection(allIdentifiers)
        if expandedIdentifiers.isEmpty {
          expandedIdentifiers.formUnion(snapshot.nodes.map(\.id))
        }
      }
      refreshFilterMetadata()
      rebuildParentLookup()
      rebuildIssueBranchIdentifiers()
      rebuildRows()
    }

    func firstVisibleNodeID() -> ParseTreeNode.ID? {
      rows.first?.id ?? snapshot.nodes.first?.id
    }

    func containsNode(with id: ParseTreeNode.ID) -> Bool {
      allIdentifiers.contains(id)
    }

    func toggleExpansion(for identifier: ParseTreeNode.ID) {
      if expandedIdentifiers.contains(identifier) {
        expandedIdentifiers.remove(identifier)
      } else {
        expandedIdentifiers.insert(identifier)
      }
      rebuildRows()
    }

    func setSeverity(_ severity: ValidationIssue.Severity, isEnabled: Bool) {
      var updated = filter
      if isEnabled {
        updated.focusedSeverities.insert(severity)
      } else {
        updated.focusedSeverities.remove(severity)
      }
      filter = updated
    }

    func setCategory(_ category: BoxCategory, isEnabled: Bool) {
      var updated = filter
      if isEnabled {
        updated.focusedCategories.insert(category)
      } else {
        updated.focusedCategories.remove(category)
      }
      filter = updated
    }

    func setShowsStreamingIndicators(_ isVisible: Bool) {
      var updated = filter
      updated.showsStreamingIndicators = isVisible
      filter = updated
    }

    func rowID(after current: ParseTreeNode.ID?, direction: NavigationDirection) -> ParseTreeNode
      .ID?
    {
      guard !rows.isEmpty else { return nil }
      let targetID = current ?? rows.first?.id
      guard let targetID, let index = rows.firstIndex(where: { $0.id == targetID }) else {
        return rows.first?.id
      }

      switch direction {
      case .down:
        let nextIndex = rows.index(after: index)
        return nextIndex < rows.endIndex ? rows[nextIndex].id : rows.last?.id
      case .up:
        if index == rows.startIndex {
          return rows.first?.id
        }
        let previousIndex = rows.index(before: index)
        return rows[previousIndex].id
      case .child:
        let row = rows[index]
        guard row.isExpanded else { return nil }
        let nextIndex = rows.index(after: index)
        guard nextIndex < rows.endIndex else { return nil }
        let nextRow = rows[nextIndex]
        return nextRow.depth > row.depth ? nextRow.id : nil
      case .parent:
        let currentDepth = rows[index].depth
        guard currentDepth > 0 else { return nil }
        var searchIndex = index
        while searchIndex > rows.startIndex {
          searchIndex = rows.index(before: searchIndex)
          if rows[searchIndex].depth < currentDepth {
            return rows[searchIndex].id
          }
        }
        return nil
      }
    }

    func issueRowID(after current: ParseTreeNode.ID?, direction: NavigationDirection)
      -> ParseTreeNode.ID?
    {
      guard !rows.isEmpty else { return nil }
      let issueIndices = rows.indices.filter { index in
        let row = rows[index]
        return row.hasValidationIssues || row.corruptionSummary != nil
      }
      guard !issueIndices.isEmpty else { return nil }

      func defaultIndex() -> Int { issueIndices.first ?? rows.startIndex }
      func lastIssueIndex() -> Int { issueIndices.last ?? rows.startIndex }

      switch direction {
      case .down, .child:
        guard let current else { return rows[defaultIndex()].id }
        guard let currentIndex = rows.firstIndex(where: { $0.id == current }) else {
          return rows[defaultIndex()].id
        }
        if let next = issueIndices.first(where: { $0 > currentIndex }) {
          return rows[next].id
        }
        return rows[defaultIndex()].id
      case .up, .parent:
        guard let current else { return rows[lastIssueIndex()].id }
        guard let currentIndex = rows.firstIndex(where: { $0.id == current }) else {
          return rows[lastIssueIndex()].id
        }
        if let previous = issueIndices.last(where: { $0 < currentIndex }) {
          return rows[previous].id
        }
        return rows[lastIssueIndex()].id
      }
    }

    func revealNode(withID identifier: ParseTreeNode.ID) {
      guard allIdentifiers.contains(identifier) else { return }
      var current = identifier
      var identifiersToExpand: Set<ParseTreeNode.ID> = []
      while let parent = parentLookup[current] {
        identifiersToExpand.insert(parent)
        current = parent
      }
      let needsRebuild = !identifiersToExpand.isSubset(of: expandedIdentifiers)
      expandedIdentifiers.formUnion(identifiersToExpand)
      if needsRebuild {
        rebuildRows()
      }
    }

    // MARK: - Private helpers

    private func rebuildRows() {
      let matcher = SearchMatcher(searchText: searchText)
      var aggregatedRows: [ParseTreeOutlineRow] = []
      var identifiers: Set<ParseTreeNode.ID> = []

      for node in snapshot.nodes {
        let result = collectRows(for: node, depth: 0, matcher: matcher)
        aggregatedRows.append(contentsOf: result.rows)
        identifiers.formUnion(result.identifiers)
      }

      expandedIdentifiers.formIntersection(identifiers)

      rows = aggregatedRows
      latencyProbe.recordLatency(for: snapshot, rowCount: rows.count)
    }

    private func collectRows(
      for node: ParseTreeNode,
      depth: Int,
      matcher: SearchMatcher
    ) -> FlattenResult {
      var identifiers: Set<ParseTreeNode.ID> = [node.id]
      var childRows: [ParseTreeOutlineRow] = []
      var anyChildVisible = false
      var anyChildMatchesSearch = false

      for child in node.children {
        let result = collectRows(for: child, depth: depth + 1, matcher: matcher)
        identifiers.formUnion(result.identifiers)
        if result.isVisible {
          anyChildVisible = true
          childRows.append(contentsOf: result.rows)
        }
        if result.matchesSearch {
          anyChildMatchesSearch = true
        }
      }

      let matchesSearch = matcher.matches(node: node)
      let subtreeMatchesSearch = matchesSearch || anyChildMatchesSearch
      let passesSearch = matcher.isActive ? subtreeMatchesSearch : true
      let matchesFilter = filter.matches(node: node)
      let passesFilter: Bool
      if filter.showsOnlyIssues {
        let isIssueBranch = issueBranchIdentifiers.contains(node.id)
        let searchOverride = matcher.isActive && matchesSearch
        passesFilter = (matchesFilter || anyChildVisible || searchOverride) && isIssueBranch
      } else {
        passesFilter = matchesFilter || anyChildVisible
      }
      let isVisible = passesSearch && passesFilter

      guard isVisible else {
        return FlattenResult(
          rows: [],
          identifiers: identifiers,
          isVisible: false,
          matchesSearch: subtreeMatchesSearch
        )
      }

      let isExpanded: Bool
      if matcher.isActive || filter.isFocused {
        isExpanded = true
      } else {
        isExpanded = expandedIdentifiers.contains(node.id)
      }

      let row = ParseTreeOutlineRow(
        node: node,
        depth: depth,
        isExpanded: isExpanded,
        isSearchMatch: matchesSearch,
        hasMatchingDescendant: anyChildMatchesSearch,
        hasValidationIssues: !node.validationIssues.isEmpty,
        corruptionSummary: ParseTreeOutlineRow.CorruptionSummary(issues: node.issues),
        statusDescriptor: ParseTreeStatusDescriptor(status: node.status)
      )

      var rows: [ParseTreeOutlineRow] = [row]
      if isExpanded {
        rows.append(contentsOf: childRows)
      }

      return FlattenResult(
        rows: rows,
        identifiers: identifiers,
        isVisible: true,
        matchesSearch: subtreeMatchesSearch
      )
    }

    private func collectIdentifiers(from nodes: [ParseTreeNode]) -> Set<ParseTreeNode.ID> {
      var identifiers: Set<ParseTreeNode.ID> = []
      var stack: [ParseTreeNode] = nodes.reversed()
      while let node = stack.popLast() {
        identifiers.insert(node.id)
        stack.append(contentsOf: node.children)
      }
      return identifiers
    }

    private func rebuildParentLookup() {
      parentLookup = [:]
      var stack: [(parent: ParseTreeNode.ID?, node: ParseTreeNode)] = snapshot.nodes.map {
        (nil, $0)
      }
      while let element = stack.popLast() {
        if let parent = element.parent {
          parentLookup[element.node.id] = parent
        }
        for child in element.node.children {
          stack.append((element.node.id, child))
        }
      }
    }

    private func rebuildIssueBranchIdentifiers() {
      issueBranchIdentifiers = []
      for node in snapshot.nodes {
        _ = markIssueBranches(for: node)
      }
    }

    @discardableResult
    private func markIssueBranches(for node: ParseTreeNode) -> Bool {
      var subtreeHasIssue = !node.validationIssues.isEmpty || !node.issues.isEmpty
      for child in node.children where markIssueBranches(for: child) {
        subtreeHasIssue = true
      }
      if subtreeHasIssue {
        issueBranchIdentifiers.insert(node.id)
      }
      return subtreeHasIssue
    }

    private func refreshFilterMetadata() {
      var categories: Set<BoxCategory> = []
      var hasStreamingIndicators = false
      var stack: [ParseTreeNode] = snapshot.nodes

      while let node = stack.popLast() {
        categories.insert(node.category)
        if node.isStreamingIndicator {
          hasStreamingIndicators = true
        }
        stack.append(contentsOf: node.children)
      }

      availableCategories = BoxCategory.allCases.filter { categories.contains($0) }
      containsStreamingIndicators = hasStreamingIndicators
    }

    private struct FlattenResult {
      let rows: [ParseTreeOutlineRow]
      let identifiers: Set<ParseTreeNode.ID>
      let isVisible: Bool
      let matchesSearch: Bool
    }

    private struct SearchMatcher {
      private let tokens: [String]

      init(searchText: String) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        tokens = trimmed.split { $0.isWhitespace }.map { $0.lowercased() }
      }

      var isActive: Bool { !tokens.isEmpty }

      func matches(node: ParseTreeNode) -> Bool {
        guard isActive else { return false }
        let haystacks: [String] = makeHaystacks(from: node)
        return tokens.allSatisfy { token in
          haystacks.contains { $0.contains(token) }
        }
      }

      private func makeHaystacks(from node: ParseTreeNode) -> [String] {
        var values: [String] = [node.header.type.description.lowercased()]
        if let metadata = node.metadata {
          values.append(metadata.name.lowercased())
          let summary = metadata.summary
          if !summary.isEmpty {
            values.append(summary.lowercased())
          }
        }
        return values
      }
    }

    private struct OutlineLatencyProbe {
      #if canImport(os)
        private let logger = Logger(
          subsystem: "ISOInspectorApp", category: "ParseTreeOutlineLatency")
      #endif

      mutating func recordLatency(for snapshot: ParseTreeSnapshot, rowCount: Int) {
        let timestamp = snapshot.lastUpdatedAt
        guard timestamp > .distantPast else { return }
        let now = Date()
        let latency = now.timeIntervalSince(timestamp)
        guard latency >= 0 else { return }
        #if canImport(os)
          logger.debug(
            "Applied snapshot with \(rowCount) rows in \(latency, format: .fixed(precision: 4))s latency"
          )
        #endif
      }
    }
  }
#endif
