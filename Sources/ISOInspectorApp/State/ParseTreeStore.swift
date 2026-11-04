#if canImport(Combine)
    import Combine
    import Dispatch
    import Foundation
    import ISOInspectorKit

    @MainActor public final class ParseTreeStore: ObservableObject {
        @Published public private(set) var snapshot: ParseTreeSnapshot
        @Published public private(set) var fileURL: URL?
        @Published public private(set) var issueMetrics: ParseIssueStore.IssueMetrics
        public let issueStore: ParseIssueStore

        private var session: Session
        private let stateSubject: CurrentValueSubject<ParseTreeStoreState, Never>
        /// The current display state, derived from the owned or mirrored session.
        public var state: ParseTreeStoreState { session.state }
        /// Publishes after the session has changed, including when a parse is replaced.
        public var statePublisher: AnyPublisher<ParseTreeStoreState, Never> {
            stateSubject.eraseToAnyPublisher()
        }
        private var builder: Builder
        private var issueFilter: ((ValidationIssue) -> Bool)?
        private var cancellables: Set<AnyCancellable> = []

        public init(
            issueStore: ParseIssueStore = ParseIssueStore(),
            initialSnapshot: ParseTreeSnapshot = .empty, initialState: ParseTreeStoreState = .idle
        ) {
            self.issueStore = issueStore
            self.snapshot = initialSnapshot
            self.session = initialState == .idle ? .idle : .mirrored(initialState)
            self.stateSubject = CurrentValueSubject(initialState)
            self.fileURL = nil
            self.issueMetrics = issueStore.metricsSnapshot()
            self.builder = Self.makeBuilder(issueStore: issueStore)
            bindIssueStore()
        }

        public func start(
            pipeline: ParsePipeline, reader: RandomAccessReader,
            context: ParsePipeline.Context = .init()
        ) {
            issueStore.reset()
            issueMetrics = issueStore.metricsSnapshot()
            fileURL = context.source?.standardizedFileURL
            var enrichedContext = context
            if enrichedContext.issueStore == nil { enrichedContext.issueStore = issueStore }
            let stream = pipeline.events(for: reader, context: enrichedContext)
            startConsuming(stream, reader: reader)
        }

        public func setValidationIssueFilter(_ filter: ((ValidationIssue) -> Bool)?) {
            issueFilter = filter
            if builder.isEmpty {
                snapshot = Self.makeFilteredSnapshot(from: snapshot, filter: filter)
            } else {
                snapshot = builder.snapshot(filter: filter)
            }
        }

        public func cancel() {
            transition(to: .cancelled)
        }

        public func shutdown() {
            transition(to: .idle)
            builder = Self.makeBuilder(issueStore: issueStore)
            snapshot = .empty
            fileURL = nil
            issueStore.reset()
            issueMetrics = issueStore.metricsSnapshot()
        }

        func replaceContents(
            snapshot: ParseTreeSnapshot, state: ParseTreeStoreState, fileURL: URL?,
            issues: [ParseIssue]
        ) {
            builder = Self.makeBuilder(issueStore: issueStore)
            issueStore.replaceAll(with: issues)
            self.fileURL = fileURL?.standardizedFileURL
            self.snapshot = Self.makeFilteredSnapshot(from: snapshot, filter: issueFilter)
            transition(to: .mirrored(state))
            self.issueMetrics = issueStore.metricsSnapshot()
        }

        private func transition(to next: Session) {
            let previous = session
            objectWillChange.send()
            session = next
            if case .parsing(let active) = previous { active.task.cancel() }
            stateSubject.send(next.state)
        }

        private static func makeBuilder(issueStore: ParseIssueStore) -> Builder {
            Builder(issueRecorder: { issue, depth in issueStore.record(issue, depth: depth) })
        }

        private static func makeFilteredSnapshot(
            from snapshot: ParseTreeSnapshot, filter: ((ValidationIssue) -> Bool)?
        ) -> ParseTreeSnapshot {
            guard let filter else { return snapshot }
            func filterNode(_ node: ParseTreeNode) -> ParseTreeNode {
                ParseTreeNode(
                    header: node.header, metadata: node.metadata, payload: node.payload,
                    validationIssues: node.validationIssues.filter(filter), issues: node.issues,
                    status: node.status, children: node.children.map(filterNode))
            }
            return ParseTreeSnapshot(
                nodes: snapshot.nodes.map(filterNode),
                validationIssues: snapshot.validationIssues.filter(filter),
                lastUpdatedAt: snapshot.lastUpdatedAt)
        }

        private func bindIssueStore() {
            issueStore.$metrics.receive(on: DispatchQueue.main).sink { [weak self] metrics in
                self?.issueMetrics = metrics
            }.store(in: &cancellables)
        }

        private func startConsuming(_ stream: ParsePipeline.EventStream, reader: RandomAccessReader) {
            builder = Self.makeBuilder(issueStore: issueStore)
            snapshot = .empty
            let taskIdentifier = UUID()
            // This task inherits MainActor isolation and cannot consume events until
            // the synchronous transition has installed its reader and identifier.
            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    for try await event in stream {
                        self.consume(event, taskIdentifier: taskIdentifier)
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
            transition(to: .parsing(ActiveParse(reader: reader, task: task, identifier: taskIdentifier)))
        }

        @MainActor private func consume(_ event: ParseEvent, taskIdentifier: UUID) {
            guard case .parsing(let active) = session, active.identifier == taskIdentifier else { return }
            builder.consume(event)
            snapshot = builder.snapshot(filter: issueFilter)
        }

        @MainActor private func finishStreaming(taskIdentifier: UUID) {
            guard case .parsing(let active) = session, active.identifier == taskIdentifier else { return }
            transition(to: .finished(active.reader))
        }

        @MainActor private func failStreaming(_ error: Error, taskIdentifier: UUID) {
            guard case .parsing(let active) = session, active.identifier == taskIdentifier else { return }
            transition(to: .failed(active.reader, makeErrorMessage(from: error)))
        }

        private func makeErrorMessage(from error: Error) -> String {
            let localizedDescription = (error as NSError).localizedDescription
            let description = String(describing: error)

            var components: [String] = []

            if !localizedDescription.isEmpty { components.append(localizedDescription) }

            if !description.isEmpty, description != localizedDescription,
                !localizedDescription.contains(description)
            {
                components.append(description)
            }

            if components.isEmpty { return String(reflecting: error) }

            return components.joined(separator: " - ")
        }
    }

    private struct ActiveParse {
        let reader: RandomAccessReader
        let task: Task<Void, Never>
        let identifier: UUID
    }

    private enum Session {
        case idle
        case parsing(ActiveParse)
        case finished(RandomAccessReader)
        case failed(RandomAccessReader, String)
        case cancelled
        // A snapshot from another window has no locally owned reader or task.
        case mirrored(ParseTreeStoreState)

        var state: ParseTreeStoreState {
            switch self {
            case .idle: .idle
            case .parsing: .parsing
            case .finished, .cancelled: .finished
            case .failed(_, let message): .failed(message)
            case .mirrored(let state): state
            }
        }
    }

    enum ParseDetailUnavailableReason: Equatable {
        case noDocument, cancelled, mirroredSnapshot
    }

    struct ParseDetailProviders {
        let hex: HexSliceProvider
        let annotations: PayloadAnnotationProvider
    }

    enum ParseDetailAccess {
        case available(ParseDetailProviders)
        case unavailable(ParseDetailUnavailableReason)
    }

    extension ParseTreeStore {
        var detailAccess: ParseDetailAccess {
            let reader: RandomAccessReader
            switch session {
            case .idle: return .unavailable(.noDocument)
            case .cancelled: return .unavailable(.cancelled)
            case .mirrored: return .unavailable(.mirroredSnapshot)
            case .parsing(let active): reader = active.reader
            case .finished(let storedReader), .failed(let storedReader, _): reader = storedReader
            }
            return .available(ParseDetailProviders(
                hex: RandomAccessHexSliceProvider(reader: reader),
                annotations: RandomAccessPayloadAnnotationProvider(reader: reader)))
        }
    }

    extension ParseTreeStore {
        fileprivate struct Builder {
            private var rootNodes: [MutableNode] = []
            private var stack: [MutableNode] = []
            private var aggregatedIssues: [ValidationIssue] = []
            private var lastUpdatedAt: Date = .distantPast
            private var placeholderIDGenerator = ParseTree.PlaceholderIDGenerator()
            private let issueRecorder: ((ParseIssue, Int) -> Void)?

            init(issueRecorder: ((ParseIssue, Int) -> Void)? = nil) {
                self.issueRecorder = issueRecorder
            }

            mutating func boxWillStart(_ header: BoxHeader, _ event: ParseEvent, _ depth: Int) {
                let node = MutableNode(
                    header: header, metadata: event.metadata, payload: event.payload,
                    validationIssues: event.validationIssues, issues: event.issues, depth: depth)
                if let parent = stack.last {
                    parent.children.append(node)
                } else {
                    rootNodes.append(node)
                }
                stack.append(node)
            }

            mutating func boxDidFinish(_ header: BoxHeader, _ event: ParseEvent) {
                guard let current = stack.last else { return }
                if current.header != header {
                    while let candidate = stack.last, candidate.header != header {
                        _ = stack.popLast()
                    }
                }
                guard let node = stack.popLast() else { return }
                if node.header == header {
                    node.metadata = node.metadata ?? event.metadata
                    if node.payload == nil || event.payload != nil {
                        node.payload = event.payload ?? node.payload
                    }
                    if !event.validationIssues.isEmpty {
                        node.validationIssues.append(contentsOf: event.validationIssues)
                    }
                    node.issues = event.issues
                    synthesizePlaceholdersIfNeeded(for: node)
                } else {
                    stack.append(node)
                }
            }

            mutating func consume(_ event: ParseEvent) {
                aggregatedIssues.append(contentsOf: event.validationIssues)
                lastUpdatedAt = Date()
                switch event.kind {
                case .willStartBox(let header, let depth): boxWillStart(header, event, depth)
                case .didFinishBox(let header, _): boxDidFinish(header, event)
                }
            }

            func snapshot(filter: ((ValidationIssue) -> Bool)?) -> ParseTreeSnapshot {
                let filteredNodes = rootNodes.map { $0.snapshot(filter: filter) }
                let filteredIssues = filter.map { aggregatedIssues.filter($0) } ?? aggregatedIssues
                return ParseTreeSnapshot(
                    nodes: filteredNodes, validationIssues: filteredIssues,
                    lastUpdatedAt: lastUpdatedAt)
            }

            fileprivate func mutableNodeFrom(
                _ placeholderHeader: BoxHeader, _ node: ParseTreeStore.MutableNode
            ) -> ParseTreeStore.MutableNode {
                return MutableNode(
                    header: placeholderHeader,
                    metadata: ParseTree.PlaceholderPlanner.metadata(for: placeholderHeader),
                    payload: nil, validationIssues: [], issues: [], depth: node.depth + 1)
            }

            fileprivate func boxHeaderFrom(
                _ requirement: ParseTree.PlaceholderPlanner.Requirement,
                _ placeholderRange: Range<Int64>
            ) -> BoxHeader {
                return BoxHeader(
                    type: requirement.childType, totalSize: 0, headerSize: 0,
                    payloadRange: placeholderRange, range: placeholderRange, uuid: nil)
            }

            fileprivate func issueFrom(
                _ requirement: ParseTree.PlaceholderPlanner.Requirement,
                _ node: ParseTreeStore.MutableNode, _ placeholderHeader: BoxHeader
            ) -> ParseIssue {
                return ParseTree.PlaceholderPlanner.makeIssue(
                    for: requirement, parent: node.header, placeholder: placeholderHeader)
            }

            private mutating func synthesizePlaceholdersIfNeeded(for node: MutableNode) {
                var existingTypes = Set(node.children.map { $0.header.type })
                let requirements = ParseTree.PlaceholderPlanner.missingRequirements(
                    for: node.header, existingChildTypes: existingTypes)
                guard !requirements.isEmpty else { return }

                if node.status != .corrupt { node.status = .partial }

                for requirement in requirements {
                    existingTypes.insert(requirement.childType)
                    let startOffset = placeholderIDGenerator.next()
                    let placeholderRange = startOffset..<startOffset
                    let placeholderHeader = boxHeaderFrom(requirement, placeholderRange)
                    let placeholderNode = mutableNodeFrom(placeholderHeader, node)
                    placeholderNode.status = .corrupt
                    let issue = issueFrom(requirement, node, placeholderHeader)
                    placeholderNode.issues = [issue]
                    node.issues.append(issue)
                    node.children.append(placeholderNode)
                    issueRecorder?(issue, node.depth + 1)
                }
            }
            var isEmpty: Bool { rootNodes.isEmpty && aggregatedIssues.isEmpty }
        }

        fileprivate final class MutableNode {
            let header: BoxHeader
            var metadata: BoxDescriptor?
            var payload: ParsedBoxPayload?
            var validationIssues: [ValidationIssue]
            var issues: [ParseIssue]
            var status: ParseTreeNode.Status
            var children: [MutableNode]
            let depth: Int

            init(
                header: BoxHeader, metadata: BoxDescriptor?, payload: ParsedBoxPayload?,
                validationIssues: [ValidationIssue], issues: [ParseIssue], depth: Int
            ) {
                self.header = header
                self.metadata = metadata
                self.payload = payload
                self.validationIssues = validationIssues
                self.issues = issues
                self.status = .valid
                self.children = []
                self.depth = depth
            }

            func snapshot(filter: ((ValidationIssue) -> Bool)?) -> ParseTreeNode {
                let filteredIssues: [ValidationIssue]
                if let filter {
                    filteredIssues = Self.uniqueIssues(from: validationIssues, applying: filter)
                } else {
                    filteredIssues = validationIssues
                }
                return ParseTreeNode(
                    header: header, metadata: metadata, payload: payload,
                    validationIssues: filteredIssues, issues: issues, status: status,
                    children: children.map { $0.snapshot(filter: filter) })
            }

            private static func uniqueIssues(
                from issues: [ValidationIssue], applying filter: (ValidationIssue) -> Bool
            ) -> [ValidationIssue] {
                var result: [ValidationIssue] = []
                for issue in issues where filter(issue) {
                    if !result.contains(issue) { result.append(issue) }
                }
                return result
            }
        }
    }
#endif
