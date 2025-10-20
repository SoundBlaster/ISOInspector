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

private final class EditListEnvironmentCoordinator: @unchecked Sendable {
    private struct TrackContext {
        var trackID: UInt32?
        var mediaTimescale: UInt32?
    }

    private var movieTimescale: UInt32?
    private var trackStack: [TrackContext] = []
    private var cachedMediaTimescales: [UInt32: UInt32] = [:]

    func willStartBox(header: BoxHeader) {
        if header.type == BoxType.track {
            trackStack.append(TrackContext())
        }
    }

    func didParsePayload(header: BoxHeader, payload: ParsedBoxPayload?) {
        switch header.type {
        case BoxType.movieHeader:
            if let movie = payload?.movieHeader {
                movieTimescale = movie.timescale
            }
        case BoxType.trackHeader:
            if let lastIndex = trackStack.indices.last,
               let detail = payload?.trackHeader {
                trackStack[lastIndex].trackID = detail.trackID
            }
        case BoxType.mediaHeader:
            guard let lastIndex = trackStack.indices.last else { return }
            guard let value = payload?.fields.first(where: { $0.name == "timescale" })?.value,
                  let timescale = UInt32(value) else { return }
            trackStack[lastIndex].mediaTimescale = timescale
            if let trackID = trackStack[lastIndex].trackID {
                cachedMediaTimescales[trackID] = timescale
            }
        default:
            break
        }
    }

    func environment(for header: BoxHeader) -> BoxParserRegistry.EditListEnvironment {
        var environment = BoxParserRegistry.EditListEnvironment(movieTimescale: movieTimescale)
        guard header.type == BoxType.editList else {
            return environment
        }
        if let lastIndex = trackStack.indices.last {
            if let timescale = trackStack[lastIndex].mediaTimescale {
                environment.mediaTimescale = timescale
            } else if let trackID = trackStack[lastIndex].trackID,
                      let cached = cachedMediaTimescales[trackID] {
                environment.mediaTimescale = cached
            }
        }
        return environment
    }

    func didFinishBox(header: BoxHeader) {
        if header.type == BoxType.track {
            if let finished = trackStack.popLast(),
               let trackID = finished.trackID,
               let timescale = finished.mediaTimescale {
                cachedMediaTimescales[trackID] = timescale
            }
        }
    }

    private enum BoxType {
        static let track = try! FourCharCode("trak")
        static let movieHeader = try! FourCharCode("mvhd")
        static let trackHeader = try! FourCharCode("tkhd")
        static let mediaHeader = try! FourCharCode("mdhd")
        static let editList = try! FourCharCode("elst")
    }
}

extension ParsePipeline {
    fileprivate static func parsePayload(
        header: BoxHeader,
        reader: RandomAccessReader,
        registry: BoxParserRegistry,
        logger: DiagnosticsLogger
    ) -> ParsedBoxPayload? {
        do {
            return try registry.parse(header: header, reader: reader)
        } catch {
            logger.error(
                "Failed to parse payload for \(header.identifierString): \(String(describing: error))"
            )
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
    public typealias Builder =
        @Sendable (_ reader: RandomAccessReader, _ context: Context) -> EventStream

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

extension ParsePipeline {
    public static func live(
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
                    let logger = DiagnosticsLogger(
                        subsystem: "ISOInspectorKit", category: "ParsePipeline")
                    var loggedUnknownTypes: Set<String> = []
                    var recordedResearchEntries: Set<ResearchLogEntry> = []
                    let activeResearchLog = context.researchLog ?? researchLog
                    let validator = BoxValidator()
                    let editListCoordinator = EditListEnvironmentCoordinator()
                    do {
                        try walker.walk(
                            reader: reader,
                            cancellationCheck: { try Task.checkCancellation() },
                            onEvent: { event in
                                let enriched: ParseEvent
                                switch event.kind {
                                case .willStartBox(let header, _):
                                    editListCoordinator.willStartBox(header: header)
                                    let descriptor = catalog.descriptor(for: header)
                                    metadataStack.append(descriptor)
                                    let payload = BoxParserRegistry.withEditListEnvironmentProvider({ request, _ in
                                        editListCoordinator.environment(for: request)
                                    }) {
                                        ParsePipeline.parsePayload(
                                            header: header,
                                            reader: reader,
                                            registry: registry,
                                            logger: logger
                                        )
                                    }
                                    editListCoordinator.didParsePayload(header: header, payload: payload)
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
                                case .didFinishBox(let header, _):
                                    let descriptor =
                                        metadataStack.popLast() ?? catalog.descriptor(for: header)
                                    editListCoordinator.didFinishBox(header: header)
                                    enriched = ParseEvent(
                                        kind: event.kind, offset: event.offset, metadata: descriptor
                                    )
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
