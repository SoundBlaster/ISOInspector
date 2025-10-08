#if canImport(Combine)
import Combine
import Dispatch
import Foundation
import ISOInspectorKit

@MainActor
public final class ParseTreeStore: ObservableObject {
    @Published public private(set) var snapshot: ParseTreeSnapshot
    @Published public private(set) var state: ParseTreeStoreState

    private let bridge: ParsePipelineEventBridge
    private var connection: ParsePipelineEventBridge.Connection?
    private var cancellable: AnyCancellable?
    private var builder = ParseTreeBuilder()

    public init(
        bridge: ParsePipelineEventBridge = ParsePipelineEventBridge(),
        initialSnapshot: ParseTreeSnapshot = .empty,
        initialState: ParseTreeStoreState = .idle
    ) {
        self.bridge = bridge
        self.snapshot = initialSnapshot
        self.state = initialState
    }

    public func start(
        pipeline: ParsePipeline,
        reader: RandomAccessReader,
        context: ParsePipeline.Context = .init()
    ) {
        let connection = bridge.makeConnection(pipeline: pipeline, reader: reader, context: context)
        bind(to: connection)
    }

    public func bind(to connection: ParsePipelineEventBridge.Connection) {
        disconnect()
        builder = ParseTreeBuilder()
        snapshot = .empty
        state = .parsing
        self.connection = connection
        cancellable = connection.events
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .finished:
                    self.state = .finished
                case let .failure(error):
                    self.state = .failed(error.localizedDescription)
                }
            }, receiveValue: { [weak self] event in
                guard let self else { return }
                self.builder.consume(event)
                self.snapshot = self.builder.snapshot()
            })
    }

    public func cancel() {
        connection?.cancel()
        disconnect()
        state = .finished
    }

    deinit {
        disconnect()
    }

    private func disconnect() {
        cancellable?.cancel()
        cancellable = nil
        connection = nil
    }
}

public struct ParseTreeSnapshot: Equatable {
    public var nodes: [ParseTreeNode]
    public var validationIssues: [ValidationIssue]
    public var lastUpdatedAt: Date

    public init(
        nodes: [ParseTreeNode],
        validationIssues: [ValidationIssue],
        lastUpdatedAt: Date = .distantPast
    ) {
        self.nodes = nodes
        self.validationIssues = validationIssues
        self.lastUpdatedAt = lastUpdatedAt
    }

    public static let empty = ParseTreeSnapshot(nodes: [], validationIssues: [], lastUpdatedAt: .distantPast)
}

public enum ParseTreeStoreState: Equatable {
    case idle
    case parsing
    case finished
    case failed(String)
}

public struct ParseTreeNode: Equatable, Identifiable {
    public let header: BoxHeader
    public var metadata: BoxDescriptor?
    public var validationIssues: [ValidationIssue]
    public var children: [ParseTreeNode]

    public var id: Int64 { header.startOffset }
}

private struct ParseTreeBuilder {
    private var rootNodes: [MutableParseTreeNode] = []
    private var stack: [MutableParseTreeNode] = []
    private var aggregatedIssues: [ValidationIssue] = []
    private var lastUpdatedAt: Date = .distantPast

    mutating func consume(_ event: ParseEvent) {
        aggregatedIssues.append(contentsOf: event.validationIssues)
        lastUpdatedAt = Date()
        switch event.kind {
        case let .willStartBox(header, _):
            let node = MutableParseTreeNode(
                header: header,
                metadata: event.metadata,
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

private final class MutableParseTreeNode {
    let header: BoxHeader
    var metadata: BoxDescriptor?
    var validationIssues: [ValidationIssue]
    var children: [MutableParseTreeNode]

    init(header: BoxHeader, metadata: BoxDescriptor?, validationIssues: [ValidationIssue]) {
        self.header = header
        self.metadata = metadata
        self.validationIssues = validationIssues
        self.children = []
    }

    func snapshot() -> ParseTreeNode {
        ParseTreeNode(
            header: header,
            metadata: metadata,
            validationIssues: validationIssues,
            children: children.map { $0.snapshot() }
        )
    }
}
#endif
