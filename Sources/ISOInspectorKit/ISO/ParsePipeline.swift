import Foundation

public struct ParseEvent: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case willStartBox(header: BoxHeader, depth: Int)
        case didFinishBox(header: BoxHeader, depth: Int)
    }

    public let kind: Kind
    public let offset: Int64
    public let metadata: BoxDescriptor?
    public let validationIssues: [ValidationIssue]

    public init(
        kind: Kind,
        offset: Int64,
        metadata: BoxDescriptor? = nil,
        validationIssues: [ValidationIssue] = []
    ) {
        self.kind = kind
        self.offset = offset
        self.metadata = metadata
        self.validationIssues = validationIssues
    }
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

    public init(buildStream: @escaping (_ reader: RandomAccessReader) -> EventStream) {
        self.buildStream = { reader, _ in buildStream(reader) }
    }

    public func events(for reader: RandomAccessReader, context: Context = .init()) -> EventStream {
        buildStream(reader, context)
    }
}

public extension ParsePipeline {
    static func live(
        catalog: BoxCatalog = .shared,
        researchLog: (any ResearchLogRecording)? = nil
    ) -> ParsePipeline {
        ParsePipeline(buildStream: { reader, context in
            AsyncThrowingStream { continuation in
                let task = Task {
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
                                    enriched = ParseEvent(kind: event.kind, offset: event.offset, metadata: descriptor)
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
