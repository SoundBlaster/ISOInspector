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

    init(
        outlineViewModel: ParseTreeOutlineViewModel,
        detailViewModel: ParseTreeDetailViewModel,
        annotations: AnnotationBookmarkSession
    ) {
        self.outlineViewModel = outlineViewModel
        self.detailViewModel = detailViewModel
        self.annotations = annotations

        outlineViewModel.$rows
            .sink { [weak self] rows in
                self?.ensureSelectionVisible(in: rows)
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
           rows.contains(where: { $0.id == current }) {
            return
        }

        select(nodeID: rows.first?.id)
    }
}
#endif
