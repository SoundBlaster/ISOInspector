#if canImport(Combine)
import Combine
import Foundation
import ISOInspectorKit

@MainActor
final class ParseTreeDetailViewModel: ObservableObject {
    @Published private(set) var detail: ParseTreeNodeDetail?
    @Published private(set) var hexError: String?

    private var snapshot: ParseTreeSnapshot = .empty
    private var selectedID: ParseTreeNode.ID?
    private var cancellables: Set<AnyCancellable> = []
    private var hexTask: Task<Void, Never>?

    private var hexSliceProvider: HexSliceProvider?
    private let windowSize: Int

    init(hexSliceProvider: HexSliceProvider?, windowSize: Int = 256) {
        self.hexSliceProvider = hexSliceProvider
        self.windowSize = windowSize
    }

    func update(hexSliceProvider: HexSliceProvider?) {
        self.hexSliceProvider = hexSliceProvider
        rebuildDetail()
    }

    func bind<P: Publisher>(to publisher: P) where P.Output == ParseTreeSnapshot, P.Failure == Never {
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

    func select(nodeID: ParseTreeNode.ID?) {
        selectedID = nodeID
        rebuildDetail()
    }

    func apply(snapshot: ParseTreeSnapshot) {
        self.snapshot = snapshot
        rebuildDetail()
    }

    private func rebuildDetail() {
        hexTask?.cancel()
        hexTask = nil
        guard let selectedID, let node = findNode(with: selectedID, in: snapshot.nodes) else {
            detail = nil
            hexError = nil
            return
        }

        let metadata = node.metadata ?? BoxCatalog.shared.descriptor(for: node.header)
        var detail = ParseTreeNodeDetail(
            header: node.header,
            metadata: metadata,
            validationIssues: node.validationIssues,
            snapshotTimestamp: snapshot.lastUpdatedAt,
            hexSlice: nil
        )
        self.detail = detail
        hexError = nil

        guard let provider = hexSliceProvider else {
            return
        }

        let window = makeWindow(for: node.header)
        guard window.length > 0 else {
            return
        }

        let request = HexSliceRequest(header: node.header, window: window)
        let currentSelection = selectedID

        hexTask = Task { [weak self] in
            do {
                let slice = try await provider.loadSlice(for: request)
                await MainActor.run {
                    guard let self, self.selectedID == currentSelection else { return }
                    var updated = detail
                    updated.hexSlice = slice
                    self.detail = updated
                }
            } catch {
                await MainActor.run {
                    guard let self, self.selectedID == currentSelection else { return }
                    self.hexError = error.localizedDescription
                }
            }
        }
    }

    private func makeWindow(for header: BoxHeader) -> HexSliceRequest.Window {
        let payloadStart = header.payloadRange.lowerBound
        let payloadLength64 = max(0, header.payloadRange.upperBound - header.payloadRange.lowerBound)
        let payloadLength = clampToInt(payloadLength64)
        let length = min(windowSize, payloadLength)
        return HexSliceRequest.Window(offset: payloadStart, length: length)
    }

    private func findNode(with id: ParseTreeNode.ID, in nodes: [ParseTreeNode]) -> ParseTreeNode? {
        var stack: [ParseTreeNode] = nodes.reversed()
        while let node = stack.popLast() {
            if node.id == id {
                return node
            }
            stack.append(contentsOf: node.children)
        }
        return nil
    }

    private func clampToInt(_ value: Int64) -> Int {
        if value <= 0 { return 0 }
        if value >= Int64(Int.max) { return Int.max }
        return Int(value)
    }
}
#endif
