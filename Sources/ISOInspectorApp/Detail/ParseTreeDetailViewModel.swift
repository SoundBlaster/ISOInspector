#if canImport(Combine)
import Combine
import Foundation
import ISOInspectorKit

@MainActor
final class ParseTreeDetailViewModel: ObservableObject {
    @Published private(set) var detail: ParseTreeNodeDetail?
    @Published private(set) var hexError: String?
    @Published private(set) var annotations: [PayloadAnnotation] = []
    @Published private(set) var annotationError: String?
    @Published private(set) var selectedAnnotationID: PayloadAnnotation.ID?
    @Published private(set) var highlightedRange: Range<Int64>?

    private var snapshot: ParseTreeSnapshot = .empty
    private var selectedID: ParseTreeNode.ID?
    private var cancellables: Set<AnyCancellable> = []
    private var hexTask: Task<Void, Never>?
    private var annotationTask: Task<Void, Never>?

    private var hexSliceProvider: HexSliceProvider?
    private var annotationProvider: PayloadAnnotationProvider?
    private let windowSize: Int

    init(hexSliceProvider: HexSliceProvider?, annotationProvider: PayloadAnnotationProvider?, windowSize: Int = 256) {
        self.hexSliceProvider = hexSliceProvider
        self.annotationProvider = annotationProvider
        self.windowSize = windowSize
    }

    func update(hexSliceProvider: HexSliceProvider?, annotationProvider: PayloadAnnotationProvider?) {
        self.hexSliceProvider = hexSliceProvider
        self.annotationProvider = annotationProvider
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

    func select(annotationID: PayloadAnnotation.ID?) {
        guard selectedAnnotationID != annotationID else { return }
        selectedAnnotationID = annotationID
        updateHighlightedRange()
    }

    func selectByte(at offset: Int64) {
        guard let annotation = annotations.first(where: { $0.byteRange.contains(offset) }) else {
            return
        }
        select(annotationID: annotation.id)
    }

    func apply(snapshot: ParseTreeSnapshot) {
        self.snapshot = snapshot
        rebuildDetail()
    }

    private func rebuildDetail() {
        hexTask?.cancel()
        hexTask = nil
        annotationTask?.cancel()
        annotationTask = nil

        guard let selectedID, let node = findNode(with: selectedID, in: snapshot.nodes) else {
            detail = nil
            hexError = nil
            annotations = []
            annotationError = nil
            selectedAnnotationID = nil
            highlightedRange = nil
            return
        }

        let metadata = node.metadata ?? BoxCatalog.shared.descriptor(for: node.header)
        let detail = ParseTreeNodeDetail(
            header: node.header,
            metadata: metadata,
            payload: node.payload,
            validationIssues: node.validationIssues,
            issues: node.issues,
            status: node.status,
            snapshotTimestamp: snapshot.lastUpdatedAt,
            hexSlice: nil
        )
        self.detail = detail
        hexError = nil

        let preservedAnnotationID = selectedAnnotationID
        annotationError = nil

        if let payload = node.payload, let derived = annotations(from: payload), !derived.isEmpty {
            annotations = derived
            if let preservedAnnotationID,
               let preserved = derived.first(where: { $0.id == preservedAnnotationID }) {
                selectedAnnotationID = preserved.id
            } else {
                selectedAnnotationID = derived.first?.id
            }
            updateHighlightedRange()
        } else {
            annotations = []
            selectedAnnotationID = nil
            highlightedRange = nil
            loadAnnotations(for: node, preserving: preservedAnnotationID)
        }
        loadHexSlice(for: node, detail: detail)
    }

    private func loadHexSlice(for node: ParseTreeNode, detail: ParseTreeNodeDetail) {
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

    private func loadAnnotations(for node: ParseTreeNode, preserving preservedID: PayloadAnnotation.ID?) {
        guard let provider = annotationProvider else {
            return
        }

        let currentSelection = selectedID
        annotationTask = Task { [weak self] in
            do {
                let annotations = try await provider.annotations(for: node.header)
                await MainActor.run {
                    guard let self, self.selectedID == currentSelection else { return }
                    self.annotationError = nil
                    let sorted = annotations.sorted { $0.byteRange.lowerBound < $1.byteRange.lowerBound }
                    self.annotations = sorted
                    if let preservedID, sorted.contains(where: { $0.id == preservedID }) {
                        self.selectedAnnotationID = preservedID
                    } else {
                        self.selectedAnnotationID = sorted.first?.id
                    }
                    self.updateHighlightedRange()
                }
            } catch {
                await MainActor.run {
                    guard let self, self.selectedID == currentSelection else { return }
                    self.annotationError = error.localizedDescription
                    self.annotations = []
                    self.selectedAnnotationID = nil
                    self.highlightedRange = nil
                }
            }
        }
    }

    private func updateHighlightedRange() {
        if let selectedAnnotationID,
           let annotation = annotations.first(where: { $0.id == selectedAnnotationID }) {
            highlightedRange = annotation.byteRange
        } else {
            highlightedRange = nil
        }
    }

    private func annotations(from payload: ParsedBoxPayload) -> [PayloadAnnotation]? {
        let mapped = payload.fields.compactMap { field -> PayloadAnnotation? in
            guard let range = field.byteRange else { return nil }
            return PayloadAnnotation(
                label: field.name,
                value: field.value,
                byteRange: range,
                summary: field.description
            )
        }
        return mapped.isEmpty ? nil : mapped
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

    deinit {
        hexTask?.cancel()
        annotationTask?.cancel()
    }
}
#endif
