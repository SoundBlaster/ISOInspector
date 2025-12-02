import Foundation

public struct ParseEvent: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case willStartBox(header: BoxHeader, depth: Int)
        case didFinishBox(header: BoxHeader, depth: Int)
    }

    public let kind: Kind
    public let offset: Int64
    public let metadata: BoxDescriptor?
    public let payload: ParsedBoxPayload?
    public let validationIssues: [ValidationIssue]
    public let issues: [ParseIssue]

    public init(
        kind: Kind, offset: Int64, metadata: BoxDescriptor? = nil, payload: ParsedBoxPayload? = nil,
        validationIssues: [ValidationIssue] = [], issues: [ParseIssue] = []
    ) {
        self.kind = kind
        self.offset = offset
        self.metadata = metadata
        self.payload = payload
        self.validationIssues = validationIssues
        self.issues = issues
    }
}

extension ParsePipeline {
    fileprivate static func parsePayload(
        header: BoxHeader, reader: RandomAccessReader, registry: BoxParserRegistry,
        logger: DiagnosticsLogger
    ) -> ParsedBoxPayload? {
        do { return try registry.parse(header: header, reader: reader) } catch {
            logger.error(
                "Failed to parse payload for \(header.identifierString): \(String(describing: error))"
            )
            return nil
        }
    }
}

@usableFromInline struct UnsafeSendable<Value>: @unchecked Sendable { let value: Value }

public struct ParsePipeline: Sendable {
    /// Configuration options for the parse pipeline.
    ///
    /// ``Options`` controls how the parser handles corrupted or malformed files,
    /// sets resource limits, and configures validation behavior.
    ///
    /// ## Topics
    ///
    /// ### Presets
    ///
    /// - ``strict``
    /// - ``tolerant``
    ///
    /// ### Configuration
    ///
    /// - ``abortOnStructuralError``
    /// - ``maxCorruptionEvents``
    /// - ``payloadValidationLevel``
    /// - ``maxTraversalDepth``
    /// - ``maxStalledIterationsPerFrame``
    /// - ``maxZeroLengthBoxesPerParent``
    /// - ``maxIssuesPerFrame``
    ///
    /// ### Validation Levels
    ///
    /// - ``PayloadValidationLevel``
    public struct Options: Equatable, Sendable {
        /// Determines the level of payload validation performed during parsing.
        public enum PayloadValidationLevel: Equatable, Sendable {
            /// Performs exhaustive semantic validation of all box payloads.
            ///
            /// Use this level for production pipelines and security-sensitive contexts
            /// where full validation is required.
            case full

            /// Validates only structural integrity without deep semantic checks.
            ///
            /// This level is faster and more tolerant of minor specification deviations.
            /// Recommended for diagnostic and forensic workflows.
            case structureOnly
        }

        /// When `true`, parsing stops immediately upon encountering structural errors.
        ///
        /// Structural errors include invalid box sizes, corrupted headers, and
        /// malformed container structures.
        ///
        /// - Default: `true` for ``strict``, `false` for ``tolerant``
        public var abortOnStructuralError: Bool

        /// Maximum number of corruption issues to record before stopping.
        ///
        /// Set to `0` to abort on the first issue. Higher values allow parsing
        /// to continue through multiple problems, useful for comprehensive
        /// corruption analysis.
        ///
        /// - Default: `0` for ``strict``, `500` for ``tolerant``
        public var maxCorruptionEvents: Int

        /// Controls the depth of payload validation.
        ///
        /// See ``PayloadValidationLevel`` for available options.
        ///
        /// - Default: `.full` for ``strict``, `.structureOnly` for ``tolerant``
        public var payloadValidationLevel: PayloadValidationLevel

        /// Maximum box nesting depth before aborting.
        ///
        /// Protects against infinite recursion or excessively nested structures.
        ///
        /// - Default: `64`
        public var maxTraversalDepth: Int

        /// Maximum stalled iterations per frame before aborting.
        ///
        /// Prevents infinite loops when parsing malformed iterative structures.
        ///
        /// - Default: `3`
        public var maxStalledIterationsPerFrame: Int

        /// Maximum zero-length boxes allowed per parent container.
        ///
        /// Prevents infinite loops caused by consecutive zero-length boxes.
        ///
        /// - Default: `2`
        public var maxZeroLengthBoxesPerParent: Int

        /// Maximum issues to record per parsing iteration.
        ///
        /// Limits memory usage when parsing severely corrupted files.
        ///
        /// - Default: `256`
        public var maxIssuesPerFrame: Int

        /// Creates a custom parse pipeline configuration.
        ///
        /// - Parameters:
        ///   - abortOnStructuralError: Stop parsing on structural errors
        ///   - maxCorruptionEvents: Maximum corruption issues to record
        ///   - payloadValidationLevel: Depth of payload validation
        ///   - maxTraversalDepth: Maximum box nesting depth
        ///   - maxStalledIterationsPerFrame: Maximum stalled iterations
        ///   - maxZeroLengthBoxesPerParent: Maximum zero-length boxes per parent
        ///   - maxIssuesPerFrame: Maximum issues per iteration
        public init(
            abortOnStructuralError: Bool = true, maxCorruptionEvents: Int = 0,
            payloadValidationLevel: PayloadValidationLevel = .full, maxTraversalDepth: Int = 64,
            maxStalledIterationsPerFrame: Int = 3, maxZeroLengthBoxesPerParent: Int = 2,
            maxIssuesPerFrame: Int = 256
        ) {
            self.abortOnStructuralError = abortOnStructuralError
            self.maxCorruptionEvents = maxCorruptionEvents
            self.payloadValidationLevel = payloadValidationLevel
            self.maxTraversalDepth = maxTraversalDepth
            self.maxStalledIterationsPerFrame = maxStalledIterationsPerFrame
            self.maxZeroLengthBoxesPerParent = maxZeroLengthBoxesPerParent
            self.maxIssuesPerFrame = maxIssuesPerFrame
        }

        /// Strict parsing mode that aborts on any structural error.
        ///
        /// Use this mode for:
        /// - Production encoding/decoding pipelines
        /// - CI/CD validation where only valid files should pass
        /// - Security-sensitive contexts where malformed files should be rejected
        ///
        /// Configuration:
        /// - Aborts immediately on structural errors
        /// - No corruption event tolerance (`maxCorruptionEvents = 0`)
        /// - Full payload validation
        ///
        /// ## See Also
        /// - <doc:TolerantParsingGuide>
        public static let strict = Options(
            abortOnStructuralError: true, maxCorruptionEvents: 0, payloadValidationLevel: .full,
            maxTraversalDepth: 64, maxStalledIterationsPerFrame: 3, maxZeroLengthBoxesPerParent: 2,
            maxIssuesPerFrame: 256)

        /// Tolerant parsing mode that continues through structural errors.
        ///
        /// Use this mode for:
        /// - Quality control workflows analyzing user-uploaded files
        /// - Forensic analysis of corrupted evidence files
        /// - Streaming server diagnostics
        /// - File recovery tools
        ///
        /// Configuration:
        /// - Continues parsing through structural errors
        /// - Records up to 500 corruption events
        /// - Structure-only payload validation for performance
        ///
        /// Example usage:
        ///
        /// ```swift
        /// let pipeline = ParsePipeline.live(options: .tolerant)
        /// let issueStore = ParseIssueStore()
        /// var context = ParsePipeline.Context(
        ///     source: fileURL,
        ///     issueStore: issueStore
        /// )
        ///
        /// for try await event in pipeline.events(for: reader, context: context) {
        ///     // Handle events...
        /// }
        ///
        /// let metrics = issueStore.metricsSnapshot()
        /// print("Errors: \(metrics.errorCount)")
        /// ```
        ///
        /// ## See Also
        /// - <doc:TolerantParsingGuide>
        public static let tolerant = Options(
            abortOnStructuralError: false, maxCorruptionEvents: 500,
            payloadValidationLevel: .structureOnly, maxTraversalDepth: 64,
            maxStalledIterationsPerFrame: 3, maxZeroLengthBoxesPerParent: 2, maxIssuesPerFrame: 256)
    }

    public struct Context: Sendable {
        public var source: URL?
        public var researchLog: (any ResearchLogRecording)?
        public var options: Options { didSet { usesAutomaticOptions = false } }
        public var issueStore: ParseIssueStore? {
            get { issueStoreBox?.value }
            set { issueStoreBox = newValue.map(UnsafeSendable.init) }
        }

        @usableFromInline internal private(set) var usesAutomaticOptions: Bool
        internal var issueStoreBox: UnsafeSendable<ParseIssueStore>?

        public init(
            source: URL? = nil, researchLog: (any ResearchLogRecording)? = nil,
            options: Options? = nil, issueStore: ParseIssueStore? = nil
        ) {
            self.source = source
            self.researchLog = researchLog
            self.options = options ?? .strict
            self.usesAutomaticOptions = options == nil
            self.issueStoreBox = issueStore.map(UnsafeSendable.init)
        }

        @usableFromInline internal mutating func applyDefaultOptions(_ defaultOptions: Options) {
            if usesAutomaticOptions {
                options = defaultOptions
                usesAutomaticOptions = false
            }
        }
    }

    public typealias EventStream = AsyncThrowingStream<ParseEvent, Error>
    public typealias Builder =
        @Sendable (_ reader: RandomAccessReader, _ context: Context) -> EventStream

    private let buildStream: Builder
    private let defaultOptions: Options

    public init(options: Options = .strict, buildStream: @escaping Builder) {
        self.defaultOptions = options
        self.buildStream = buildStream
    }

    public init(buildStream: @escaping Builder) {
        self.init(options: .strict, buildStream: buildStream)
    }

    public init(_ buildStream: @escaping Builder) {
        self.init(options: .strict, buildStream: buildStream)
    }

    public init(buildStream: @escaping @Sendable (_ reader: RandomAccessReader) -> EventStream) {
        self.init(options: .strict) { reader, _ in buildStream(reader) }
    }

    public func events(for reader: RandomAccessReader, context: Context = .init()) -> EventStream {
        var resolvedContext = context
        resolvedContext.applyDefaultOptions(defaultOptions)
        return buildStream(reader, resolvedContext)
    }
}

extension ParsePipeline {
    public static func live(
        catalog: BoxCatalog = .shared, researchLog: (any ResearchLogRecording)? = nil,
        registry: BoxParserRegistry = .shared, options: Options = .strict
    ) -> ParsePipeline {
        ParsePipeline(
            options: options,
            buildStream: { reader, context in
                let readerBox = UnsafeSendable(value: reader)
                let contextBox = UnsafeSendable(value: context)

                return AsyncThrowingStream { continuation in
                    let task = Task {
                        let reader = readerBox.value
                        let context = contextBox.value
                        let walker = StreamingBoxWalker()
                        var metadataStack: [BoxDescriptor?] = []
                        let logger = DiagnosticsLogger(
                            subsystem: "ISOInspectorKit", category: "ParsePipeline")
                        var loggedUnknownTypes: Set<String> = []
                        var recordedResearchEntries: Set<ResearchLogEntry> = []
                        let activeResearchLog = context.researchLog ?? researchLog
                        let validator = BoxValidator()
                        let editListCoordinator = EditListEnvironmentCoordinator()
                        let metadataCoordinator = MetadataEnvironmentCoordinator()
                        let fragmentCoordinator = FragmentEnvironmentCoordinator()
                        let randomAccessCoordinator = RandomAccessIndexCoordinator()
                        var issuesByNodeID: [Int64: [ParseIssue]] = [:]
                        let issueStore = context.issueStore
                        issueStore?.reset()
                        do {
                            try walker.walk(
                                reader: reader, cancellationCheck: { try Task.checkCancellation() },
                                options: context.options,
                                onEvent: { event in
                                    let enriched: ParseEvent
                                    var nodeIDToRemove: Int64?
                                    switch event.kind {
                                    case .willStartBox(let header, _):
                                        editListCoordinator.willStartBox(header: header)
                                        metadataCoordinator.willStartBox(header: header)
                                        fragmentCoordinator.willStartBox(header: header)
                                        randomAccessCoordinator.willStartBox(header: header)
                                        let descriptor = catalog.descriptor(for: header)
                                        metadataStack.append(descriptor)
                                        let payload =
                                            BoxParserRegistry.withEditListEnvironmentProvider({
                                                request, _ in
                                                editListCoordinator.environment(for: request)
                                            }) {
                                                BoxParserRegistry.withMetadataEnvironmentProvider({
                                                    request, _ in
                                                    metadataCoordinator.environment(for: request)
                                                }) {
                                                    BoxParserRegistry
                                                        .withFragmentEnvironmentProvider({
                                                            request, _ in
                                                            fragmentCoordinator.environment(
                                                                for: request)
                                                        }) {
                                                            BoxParserRegistry
                                                                .withRandomAccessEnvironmentProvider(
                                                                    { request, _ in
                                                                        randomAccessCoordinator
                                                                            .environment(
                                                                                for: request)
                                                                    }) {
                                                                    ParsePipeline.parsePayload(
                                                                        header: header,
                                                                        reader: reader,
                                                                        registry: registry,
                                                                        logger: logger)
                                                                }
                                                        }
                                                }
                                            }
                                        editListCoordinator.didParsePayload(
                                            header: header, payload: payload)
                                        metadataCoordinator.didParsePayload(
                                            header: header, payload: payload)
                                        fragmentCoordinator.didParsePayload(
                                            header: header, payload: payload)
                                        randomAccessCoordinator.didParsePayload(
                                            header: header, payload: payload)
                                        if descriptor == nil {
                                            let key = header.identifierString
                                            if loggedUnknownTypes.insert(key).inserted {
                                                logger.info("Unknown box encountered: \(key)")
                                            }
                                            if let researchLog = activeResearchLog {
                                                let filePath = context.source?.path ?? ""
                                                let entry = ResearchLogEntry(
                                                    boxType: key, filePath: filePath,
                                                    startOffset: header.startOffset,
                                                    endOffset: header.endOffset)
                                                if recordedResearchEntries.insert(entry).inserted {
                                                    researchLog.record(entry)
                                                }
                                            }
                                        }
                                        enriched = ParseEvent(
                                            kind: event.kind, offset: event.offset,
                                            metadata: descriptor, payload: payload,
                                            issues: issuesByNodeID[header.startOffset] ?? [])
                                    case .didFinishBox(let header, _):
                                        let descriptor =
                                            metadataStack.popLast()
                                            ?? catalog.descriptor(for: header)
                                        let fragmentPayload = fragmentCoordinator.didFinishBox(
                                            header: header)
                                        let randomAccessPayload =
                                            randomAccessCoordinator.didFinishBox(
                                                header: header, payload: fragmentPayload)
                                        editListCoordinator.didFinishBox(header: header)
                                        metadataCoordinator.didFinishBox(header: header)
                                        enriched = ParseEvent(
                                            kind: event.kind, offset: event.offset,
                                            metadata: descriptor,
                                            payload: randomAccessPayload ?? fragmentPayload,
                                            issues: issuesByNodeID[header.startOffset] ?? [])
                                        nodeIDToRemove = header.startOffset
                                    }
                                    let validated = validator.annotate(
                                        event: enriched, reader: reader)
                                    let finalEvent = ParsePipeline.attachParseIssuesIfNeeded(
                                        to: validated, options: context.options,
                                        issueStore: issueStore, issuesByNodeID: &issuesByNodeID)
                                    if let nodeID = nodeIDToRemove {
                                        issuesByNodeID.removeValue(forKey: nodeID)
                                    }
                                    continuation.yield(finalEvent)
                                },
                                onIssue: { issue, depth in
                                    issueStore?.record(issue, depth: depth)
                                    for nodeID in issue.affectedNodeIDs {
                                        issuesByNodeID[nodeID, default: []].append(issue)
                                    }
                                }, onFinish: { continuation.finish() })
                        } catch { continuation.finish(throwing: error) }
                    }

                    continuation.onTermination = { @Sendable _ in task.cancel() }
                }
            })
    }

    private static func attachParseIssuesIfNeeded(
        to event: ParseEvent, options: Options, issueStore: ParseIssueStore?,
        issuesByNodeID: inout [Int64: [ParseIssue]]
    ) -> ParseEvent {
        guard !event.validationIssues.isEmpty else { return event }
        guard !options.abortOnStructuralError else { return event }

        let header: BoxHeader
        let depth: Int
        switch event.kind {
        case .willStartBox(let resolvedHeader, let resolvedDepth):
            header = resolvedHeader
            depth = resolvedDepth
        case .didFinishBox(let resolvedHeader, let resolvedDepth):
            header = resolvedHeader
            depth = resolvedDepth
        }

        let promotableIssues = event.validationIssues.filter(shouldPromoteToParseIssue)
        guard !promotableIssues.isEmpty else { return event }

        let parseIssues = promotableIssues.map { issue in
            ParseIssue(
                severity: ParseIssue.Severity(validationSeverity: issue.severity),
                code: issue.ruleID, message: issue.message, byteRange: header.range,
                affectedNodeIDs: [header.startOffset])
        }

        for issue in parseIssues { issuesByNodeID[header.startOffset, default: []].append(issue) }
        if let issueStore { issueStore.record(parseIssues) { _ in depth } }

        let combinedIssues = issuesByNodeID[header.startOffset] ?? []
        return ParseEvent(
            kind: event.kind, offset: event.offset, metadata: event.metadata,
            payload: event.payload, validationIssues: event.validationIssues, issues: combinedIssues
        )
    }

    private static func shouldPromoteToParseIssue(_ issue: ValidationIssue) -> Bool {
        guard issue.ruleID.hasPrefix("VR-") else { return false }
        let suffix = issue.ruleID.dropFirst(3)
        guard let number = Int(suffix), (1...15).contains(number) else { return false }
        return true
    }
}
