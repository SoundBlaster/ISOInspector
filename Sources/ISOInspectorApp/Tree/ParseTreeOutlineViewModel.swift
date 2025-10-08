#if canImport(Combine)
import Combine
import Foundation
import ISOInspectorKit

@MainActor
final class ParseTreeOutlineViewModel: ObservableObject {
    @Published private(set) var rows: [ParseTreeOutlineRow] = []
    @Published var searchText: String = "" {
        didSet { rebuildRows() }
    }
    @Published var filter: ParseTreeOutlineFilter = .all {
        didSet { rebuildRows() }
    }

    private var snapshot: ParseTreeSnapshot = .empty
    private var expandedIdentifiers: Set<ParseTreeNode.ID> = []

    init(snapshot: ParseTreeSnapshot = .empty) {
        apply(snapshot: snapshot)
    }

    func apply(snapshot: ParseTreeSnapshot) {
        self.snapshot = snapshot
        let allIdentifiers = collectIdentifiers(from: snapshot.nodes)
        if expandedIdentifiers.isEmpty {
            expandedIdentifiers.formUnion(snapshot.nodes.map(\.id))
        } else {
            expandedIdentifiers.formIntersection(allIdentifiers)
            if expandedIdentifiers.isEmpty {
                expandedIdentifiers.formUnion(snapshot.nodes.map(\.id))
            }
        }
        rebuildRows()
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
        if expandedIdentifiers.isEmpty {
            expandedIdentifiers.formUnion(snapshot.nodes.map(\.id))
        }

        rows = aggregatedRows
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
        let passesFilter = matchesFilter || anyChildVisible
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
            hasValidationIssues: !node.validationIssues.isEmpty
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
}

struct ParseTreeOutlineRow: Identifiable, Equatable {
    let node: ParseTreeNode
    let depth: Int
    let isExpanded: Bool
    let isSearchMatch: Bool
    let hasMatchingDescendant: Bool
    let hasValidationIssues: Bool

    var id: ParseTreeNode.ID { node.id }
    var typeDescription: String { node.header.type.description }
    var displayName: String { node.metadata?.name ?? typeDescription }
    var summary: String? { node.metadata?.summary }
    var dominantSeverity: ValidationIssue.Severity? {
        node.validationIssues.map(\.severity).max(by: { $0.priority < $1.priority })
    }
}

struct ParseTreeOutlineFilter: Equatable {
    var focusedSeverities: Set<ValidationIssue.Severity>

    init(focusedSeverities: Set<ValidationIssue.Severity> = []) {
        self.focusedSeverities = focusedSeverities
    }

    static let all = ParseTreeOutlineFilter()

    var isFocused: Bool { !focusedSeverities.isEmpty }

    func matches(node: ParseTreeNode) -> Bool {
        guard !focusedSeverities.isEmpty else { return true }
        return node.validationIssues.contains { focusedSeverities.contains($0.severity) }
    }
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
            if let summary = metadata.summary {
                values.append(summary.lowercased())
            }
        }
        return values
    }
}

private extension ValidationIssue.Severity {
    var priority: Int {
        switch self {
        case .info: return 0
        case .warning: return 1
        case .error: return 2
        }
    }
}

extension ValidationIssue.Severity: CaseIterable {}

// @todo #6 Add box category and streaming metadata filters once corresponding models are available.
#endif
