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

    public init(
        kind: Kind,
        offset: Int64,
        metadata: BoxDescriptor? = nil,
        payload: ParsedBoxPayload? = nil,
        validationIssues: [ValidationIssue] = []
    ) {
        self.kind = kind
        self.offset = offset
        self.metadata = metadata
        self.payload = payload
        self.validationIssues = validationIssues
    }
}

private extension ParsePipeline {
    static func parsePayload(
        header: BoxHeader,
        reader: RandomAccessReader,
        registry: BoxParserRegistry,
        logger: DiagnosticsLogger
    ) -> ParsedBoxPayload? {
        do {
            return try registry.parse(header: header, reader: reader)
        } catch {
            logger.error("Failed to parse payload for \(header.identifierString): \(String(describing: error))")
            return nil
        }
    }
}

private struct UnsafeSendable<Value>: @unchecked Sendable {
    let value: Value
}

public struct ParsePipeline: Sendable {
    public struct Context: Sendable {
        public var source: URL?
        public var researchLog: (any ResearchLogRecording)?

        public init(source: URL? = nil, researchLog: (any ResearchLogRecording)? = nil) {
            self.source = source
            self.researchLog = researchLog
        }
    }

    public typealias EventStream = AsyncThrowingStream<ParseEvent, Error>
    public typealias Builder = @Sendable (_ reader: RandomAccessReader, _ context: Context) -> EventStream

    private let buildStream: Builder

    public init(buildStream: @escaping Builder) {
        self.buildStream = buildStream
    }

    public init(_ buildStream: @escaping Builder) {
        self.buildStream = buildStream
    }

    public init(buildStream: @escaping @Sendable (_ reader: RandomAccessReader) -> EventStream) {
        self.buildStream = { reader, _ in buildStream(reader) }
    }

    public func events(for reader: RandomAccessReader, context: Context = .init()) -> EventStream {
        buildStream(reader, context)
    }
}

extension AsyncThrowingStream: @unchecked Sendable where Element: Sendable {}

public extension ParsePipeline {
    static func live(
        catalog: BoxCatalog = .shared,
        researchLog: (any ResearchLogRecording)? = nil,
        registry: BoxParserRegistry = .shared
    ) -> ParsePipeline {
        ParsePipeline(buildStream: { reader, context in
            let readerBox = UnsafeSendable(value: reader)
            let contextBox = UnsafeSendable(value: context)

            return AsyncThrowingStream { continuation in
                let task = Task {
                    let reader = readerBox.value
                    let context = contextBox.value
                    let walker = StreamingBoxWalker()
                    var metadataStack: [BoxDescriptor?] = []
                    let logger = DiagnosticsLogger(subsystem: "ISOInspectorKit", category: "ParsePipeline")
                    var loggedUnknownTypes: Set<String> = []
                    var recordedResearchEntries: Set<ResearchLogEntry> = []
                    let activeResearchLog = context.researchLog ?? researchLog
                    let validator = BoxValidator()
                    do {
                        try walker.walk(
                            reader: reader,
                            cancellationCheck: { try Task.checkCancellation() },
                            onEvent: { event in
                                let enriched: ParseEvent
                                switch event.kind {
                                case let .willStartBox(header, _):
                                    let descriptor = catalog.descriptor(for: header)
                                    metadataStack.append(descriptor)
                                    let payload = ParsePipeline.parsePayload(
                                        header: header,
                                        reader: reader,
                                        registry: registry,
                                        logger: logger
                                    )
                                    if descriptor == nil {
                                        let key = header.identifierString
                                        if loggedUnknownTypes.insert(key).inserted {
                                            logger.info("Unknown box encountered: \(key)")
                                        }
                                        if let researchLog = activeResearchLog {
                                            let filePath = context.source?.path ?? ""
                                            let entry = ResearchLogEntry(
                                                boxType: key,
                                                filePath: filePath,
                                                startOffset: header.startOffset,
                                                endOffset: header.endOffset
                                            )
                                            if recordedResearchEntries.insert(entry).inserted {
                                                researchLog.record(entry)
                                            }
                                        }
                                    }
                                    enriched = ParseEvent(
                                        kind: event.kind,
                                        offset: event.offset,
                                        metadata: descriptor,
                                        payload: payload
                                    )
                                case let .didFinishBox(header, _):
                                    let descriptor = metadataStack.popLast() ?? catalog.descriptor(for: header)
                                    enriched = ParseEvent(kind: event.kind, offset: event.offset, metadata: descriptor)
                                }
                                let validated = validator.annotate(event: enriched, reader: reader)
                                continuation.yield(validated)
                            },
                            onFinish: {
                                continuation.finish()
                            }
                        )
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }

                continuation.onTermination = { @Sendable _ in
                    task.cancel()
                }
            }
        })
    }
}
