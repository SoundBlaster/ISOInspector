#if canImport(Combine)
import Combine
import Dispatch
import Foundation
import ISOInspectorKit

@MainActor
public final class ParseTreeStore: ObservableObject {
    @Published public private(set) var snapshot: ParseTreeSnapshot
    @Published public private(set) var state: ParseTreeStoreState
    @Published public private(set) var fileURL: URL?
    @Published public private(set) var issueMetrics: ParseIssueStore.IssueMetrics
    public let issueStore: ParseIssueStore

    private let resources = ResourceBag()
    private var builder = Builder()
    private var issueFilter: ((ValidationIssue) -> Bool)?
    private var cancellables: Set<AnyCancellable> = []

    public init(
        issueStore: ParseIssueStore = ParseIssueStore(),
        initialSnapshot: ParseTreeSnapshot = .empty,
        initialState: ParseTreeStoreState = .idle
    ) {
        self.issueStore = issueStore
        self.snapshot = initialSnapshot
        self.state = initialState
        self.fileURL = nil
        self.issueMetrics = issueStore.metricsSnapshot()
        bindIssueStore()
    }

    public func start(
        pipeline: ParsePipeline,
        reader: RandomAccessReader,
        context: ParsePipeline.Context = .init()
    ) {
        issueStore.reset()
        resources.reader = reader
        fileURL = context.source?.standardizedFileURL
        var enrichedContext = context
        if enrichedContext.issueStore == nil {
            enrichedContext.issueStore = issueStore
        }
        let stream = pipeline.events(for: reader, context: enrichedContext)
        startConsuming(stream)
    }

    public func setValidationIssueFilter(_ filter: ((ValidationIssue) -> Bool)?) {
        issueFilter = filter
        snapshot = builder.snapshot(filter: filter)
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
        issueStore.reset()
    }

    private func disconnect() {
        resources.stop()
    }

    private func bindIssueStore() {
        issueStore.$metrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.issueMetrics = metrics
            }
            .store(in: &cancellables)
    }

    private func startConsuming(_ stream: ParsePipeline.EventStream) {
        disconnect()
        builder = Builder()
        snapshot = .empty
        state = .parsing
        let taskIdentifier = UUID()
        resources.reserveStreamingTaskIdentifier(taskIdentifier)
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                for try await event in stream {
                    self.consume(event)
                }
                self.finishStreaming(taskIdentifier: taskIdentifier)
            } catch {
                if error is CancellationError {
                    self.finishStreaming(taskIdentifier: taskIdentifier)
                } else {
                    self.failStreaming(error, taskIdentifier: taskIdentifier)
                }
            }
        }
        resources.setStreamingTask(task, identifier: taskIdentifier)
    }

    @MainActor
    private func consume(_ event: ParseEvent) {
        builder.consume(event)
        snapshot = builder.snapshot(filter: issueFilter)
    }

    @MainActor
    private func finishStreaming(taskIdentifier: UUID) {
        guard resources.clearStreamingTask(matching: taskIdentifier) else { return }
        if state == .parsing {
            state = .finished
        }
    }

    @MainActor
    private func failStreaming(_ error: Error, taskIdentifier: UUID) {
        guard resources.clearStreamingTask(matching: taskIdentifier) else { return }
        state = .failed(makeErrorMessage(from: error))
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
    private(set) var streamingTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var streamingTaskIdentifier: UUID?

    var reader: RandomAccessReader?

    func setStreamingTask(_ task: Task<Void, Never>?, identifier: UUID) {
        streamingTaskIdentifier = identifier
        streamingTask = task
    }

    func reserveStreamingTaskIdentifier(_ identifier: UUID) {
        streamingTaskIdentifier = identifier
    }

    @discardableResult
    func clearStreamingTask(matching identifier: UUID) -> Bool {
        guard streamingTaskIdentifier == identifier else { return false }
        streamingTask = nil
        streamingTaskIdentifier = nil
        return true
    }

    func clearStreamingTask() {
        streamingTask?.cancel()
        streamingTask = nil
        streamingTaskIdentifier = nil
    }

    func stop() {
        clearStreamingTask()
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
            case .willStartBox(let header, _):
                let node = MutableNode(
                    header: header,
                    metadata: event.metadata,
                    payload: event.payload,
                    validationIssues: event.validationIssues,
                    issues: event.issues
                )
                if let parent = stack.last {
                    parent.children.append(node)
                } else {
                    rootNodes.append(node)
                }
                stack.append(node)
            case .didFinishBox(let header, _):
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
                    if !event.issues.isEmpty {
                        if node.issues.isEmpty {
                            node.issues = event.issues
                        } else {
                            node.issues.append(contentsOf: event.issues)
                        }
                    }
                } else {
                    stack.append(node)
                }
            }
        }

        func snapshot(filter: ((ValidationIssue) -> Bool)?) -> ParseTreeSnapshot {
            let filteredNodes = rootNodes.map { $0.snapshot(filter: filter) }
            let filteredIssues = filter.map { aggregatedIssues.filter($0) } ?? aggregatedIssues
            return ParseTreeSnapshot(
                nodes: filteredNodes,
                validationIssues: filteredIssues,
                lastUpdatedAt: lastUpdatedAt
            )
        }
    }

    fileprivate final class MutableNode {
        let header: BoxHeader
        var metadata: BoxDescriptor?
        var payload: ParsedBoxPayload?
        var validationIssues: [ValidationIssue]
        var issues: [ParseIssue]
        var status: ParseTreeNode.Status
        var children: [MutableNode]

        init(
            header: BoxHeader, metadata: BoxDescriptor?, payload: ParsedBoxPayload?,
            validationIssues: [ValidationIssue], issues: [ParseIssue]
        ) {
            self.header = header
            self.metadata = metadata
            self.payload = payload
            self.validationIssues = validationIssues
            self.issues = issues
            self.status = .valid
            self.children = []
        }

        func snapshot(filter: ((ValidationIssue) -> Bool)?) -> ParseTreeNode {
            let filteredIssues = filter.map { validationIssues.filter($0) } ?? validationIssues
            return ParseTreeNode(
                header: header,
                metadata: metadata,
                payload: payload,
                validationIssues: filteredIssues,
                issues: issues,
                status: status,
                children: children.map { $0.snapshot(filter: filter) }
            )
        }
    }
}
#endif
