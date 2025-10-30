#if canImport(Combine)
    import Combine
    import Foundation
    import ISOInspectorKit

    @MainActor
    final class NodeSelectionViewModel: ObservableObject {
        @Published private(set) var selectedNodeID: ParseTreeNode.ID?

        private let outlineViewModel: ParseTreeOutlineViewModel
        private let detailViewModel: ParseTreeDetailViewModel
        private let annotations: AnnotationBookmarkSession
        private var cancellables: Set<AnyCancellable> = []
        private var needsFilterDrivenSelectionUpdate = false
        private var activeFilter: ParseTreeOutlineFilter

        init(
            outlineViewModel: ParseTreeOutlineViewModel,
            detailViewModel: ParseTreeDetailViewModel,
            annotations: AnnotationBookmarkSession
        ) {
            self.outlineViewModel = outlineViewModel
            self.detailViewModel = detailViewModel
            self.annotations = annotations
            self.activeFilter = outlineViewModel.filter

            outlineViewModel.$rows
                .sink { [weak self] rows in
                    self?.ensureSelectionVisible(in: rows)
                }
                .store(in: &cancellables)

            outlineViewModel.$filter
                .dropFirst()
                .sink { [weak self] newFilter in
                    guard let self else { return }
                    self.activeFilter = newFilter
                    self.needsFilterDrivenSelectionUpdate = true
                    self.ensureSelectionVisible(in: self.outlineViewModel.rows)
                }
                .store(in: &cancellables)
        }

        var selectionPublisher: AnyPublisher<ParseTreeNode.ID?, Never> {
            $selectedNodeID.eraseToAnyPublisher()
        }

        func select(nodeID: ParseTreeNode.ID?) {
            guard selectedNodeID != nodeID else { return }
            selectedNodeID = nodeID
            detailViewModel.select(nodeID: nodeID)
            annotations.setSelectedNode(nodeID)
        }

        func handleSnapshotUpdate(snapshot: ParseTreeSnapshot) {
            guard !snapshot.nodes.isEmpty else {
                select(nodeID: nil)
                return
            }

            if let current = selectedNodeID,
                snapshot.containsNode(with: current) {
                return
            }

            let fallback = outlineViewModel.firstVisibleNodeID() ?? snapshot.nodes.first?.id
            if selectedNodeID != fallback {
                select(nodeID: fallback)
            }
        }

        private func ensureSelectionVisible(in rows: [ParseTreeOutlineRow]) {
            guard !rows.isEmpty else {
                if selectedNodeID != nil {
                    select(nodeID: nil)
                }
                return
            }

            if let current = selectedNodeID,
                rows.contains(where: { $0.id == current }),
                !needsFilterDrivenSelectionUpdate {
                return
            }
            needsFilterDrivenSelectionUpdate = false

            let filter = activeFilter
            var candidateID: ParseTreeNode.ID?
            if filter.isFocused {
                candidateID = rows.first(where: { rowMatchesActiveFilter($0, filter: filter) })?.id
            }
            if candidateID == nil, !outlineViewModel.searchText.isEmpty {
                candidateID = rows.first(where: { $0.isSearchMatch })?.id
            }
            select(nodeID: candidateID ?? rows.first?.id)
        }

        private func rowMatchesActiveFilter(
            _ row: ParseTreeOutlineRow,
            filter: ParseTreeOutlineFilter
        ) -> Bool {
            if !filter.focusedSeverities.isEmpty {
                let validationMatch = row.node.validationIssues.contains { issue in
                    filter.focusedSeverities.contains(issue.severity)
                }
                let parseMatch = row.node.issues.contains { issue in
                    switch issue.severity {
                    case .error:
                        return filter.focusedSeverities.contains(.error)
                    case .warning:
                        return filter.focusedSeverities.contains(.warning)
                    case .info:
                        return filter.focusedSeverities.contains(.info)
                    }
                }
                if !(validationMatch || parseMatch) {
                    return false
                }
            }

            if !filter.focusedCategories.isEmpty,
                !filter.focusedCategories.contains(row.node.category) {
                return false
            }

            if !filter.showsStreamingIndicators && row.node.isStreamingIndicator {
                return false
            }

            if filter.showsOnlyIssues {
                let hasParseIssues = !row.node.issues.isEmpty
                let hasValidationIssues = !row.node.validationIssues.isEmpty
                if !(hasParseIssues || hasValidationIssues) {
                    return false
                }
            }

            return true
        }
    }
#endif
