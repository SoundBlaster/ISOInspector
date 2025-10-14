#if canImport(Combine)
import Combine
import Dispatch
import Foundation

#if canImport(ISOInspectorKit_iOS)
import ISOInspectorKit_iOS
#endif
#if canImport(ISOInspectorKit_macOS)
import ISOInspectorKit_macOS
#endif
#if canImport(ISOInspectorKit_ipadOS)
import ISOInspectorKit_ipadOS
#endif

@MainActor
public final class ParseTreeStore: ObservableObject {
    @Published public private(set) var snapshot: ParseTreeSnapshot
    @Published public private(set) var state: ParseTreeStoreState
    @Published public private(set) var fileURL: URL?

    private let bridge: ParsePipelineEventBridge
    private let resources = ResourceBag()
    private var builder = Builder()

    public init(
        bridge: ParsePipelineEventBridge = ParsePipelineEventBridge(),
        initialSnapshot: ParseTreeSnapshot = .empty,
        initialState: ParseTreeStoreState = .idle
    ) {
        self.bridge = bridge
        self.snapshot = initialSnapshot
        self.state = initialState
        self.fileURL = nil
    }

    public func start(
        pipeline: ParsePipeline,
        reader: RandomAccessReader,
        context: ParsePipeline.Context = .init()
    ) {
        resources.reader = reader
        fileURL = context.source?.standardizedFileURL
        let connection = bridge.makeConnection(pipeline: pipeline, reader: reader, context: context)
        bind(to: connection)
    }

    public func bind(to connection: ParsePipelineEventBridge.Connection) {
        disconnect()
        builder = Builder()
        snapshot = .empty
        state = .parsing
        resources.connection = connection
        resources.cancellable = connection.events
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .finished:
                    self.state = .finished
                case let .failure(error):
                    self.state = .failed(self.makeErrorMessage(from: error))
                }
            }, receiveValue: { [weak self] event in
                guard let self else { return }
                self.builder.consume(event)
                self.snapshot = self.builder.snapshot()
            })
    }

    public func cancel() {
        disconnect()
        state = .finished
    }

    public func shutdown() {
        disconnect()
        builder = Builder()
        snapshot = .empty
        state = .idle
        fileURL = nil
    }

    private func disconnect() {
        resources.stop()
    }

    private func makeErrorMessage(from error: Error) -> String {
        let localizedDescription = (error as NSError).localizedDescription
        let description = String(describing: error)

        var components: [String] = []

        if !localizedDescription.isEmpty {
            components.append(localizedDescription)
        }

        if !description.isEmpty,
           description != localizedDescription,
           !localizedDescription.contains(description) {
            components.append(description)
        }

        if components.isEmpty {
            return String(reflecting: error)
        }

        return components.joined(separator: " - ")
    }
}

extension ParseTreeStore {
    func makeHexSliceProvider() -> HexSliceProvider? {
        guard let reader = resources.reader else { return nil }
        return RandomAccessHexSliceProvider(reader: reader)
    }

    func makePayloadAnnotationProvider() -> PayloadAnnotationProvider? {
        guard let reader = resources.reader else { return nil }
        return RandomAccessPayloadAnnotationProvider(reader: reader)
    }
}

@MainActor
private final class ResourceBag {
    var connection: ParsePipelineEventBridge.Connection? {
        didSet { oldValue?.cancel() }
    }

    var cancellable: AnyCancellable? {
        didSet { oldValue?.cancel() }
    }

    var reader: RandomAccessReader?

    func stop() {
        cancellable = nil
        connection = nil
        reader = nil
    }
}

extension ParseTreeStore {
    fileprivate struct Builder {
        private var rootNodes: [MutableNode] = []
        private var stack: [MutableNode] = []
        private var aggregatedIssues: [ValidationIssue] = []
        private var lastUpdatedAt: Date = .distantPast

        mutating func consume(_ event: ParseEvent) {
            aggregatedIssues.append(contentsOf: event.validationIssues)
            lastUpdatedAt = Date()
            switch event.kind {
            case let .willStartBox(header, _):
                let node = MutableNode(
                    header: header,
                    metadata: event.metadata,
                    payload: event.payload,
                    validationIssues: event.validationIssues
                )
                if let parent = stack.last {
                    parent.children.append(node)
                } else {
                    rootNodes.append(node)
                }
                stack.append(node)
            case let .didFinishBox(header, _):
                guard let current = stack.last else {
                    return
                }
                if current.header != header {
                    while let candidate = stack.last, candidate.header != header {
                        _ = stack.popLast()
                    }
                }
                guard let node = stack.popLast() else {
                    return
                }
                if node.header == header {
                    node.metadata = node.metadata ?? event.metadata
                    if node.payload == nil || event.payload != nil {
                        node.payload = event.payload ?? node.payload
                    }
                    if !event.validationIssues.isEmpty {
                        node.validationIssues.append(contentsOf: event.validationIssues)
                    }
                } else {
                    stack.append(node)
                }
            }
        }

        func snapshot() -> ParseTreeSnapshot {
            ParseTreeSnapshot(
                nodes: rootNodes.map { $0.snapshot() },
                validationIssues: aggregatedIssues,
                lastUpdatedAt: lastUpdatedAt
            )
        }
    }

    fileprivate final class MutableNode {
        let header: BoxHeader
        var metadata: BoxDescriptor?
        var payload: ParsedBoxPayload?
        var validationIssues: [ValidationIssue]
        var children: [MutableNode]

        init(header: BoxHeader, metadata: BoxDescriptor?, payload: ParsedBoxPayload?, validationIssues: [ValidationIssue]) {
            self.header = header
            self.metadata = metadata
            self.payload = payload
            self.validationIssues = validationIssues
            self.children = []
        }

        func snapshot() -> ParseTreeNode {
            ParseTreeNode(
                header: header,
                metadata: metadata,
                payload: payload,
                validationIssues: validationIssues,
                children: children.map { $0.snapshot() }
            )
        }
    }
}
#endif
