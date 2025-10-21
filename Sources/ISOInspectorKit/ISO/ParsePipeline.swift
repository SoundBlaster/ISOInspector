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

private final class MetadataEnvironmentCoordinator: @unchecked Sendable {
    private struct Context {
        var handlerType: HandlerType?
        var keyTable: [UInt32: ParsedBoxPayload.MetadataKeyTableBox.Entry] = [:]
    }

    private var stack: [Context] = []

    func willStartBox(header: BoxHeader) {
        if header.type == BoxType.metadata {
            stack.append(Context())
        }
    }

    func didParsePayload(header: BoxHeader, payload: ParsedBoxPayload?) {
        guard !stack.isEmpty else { return }
        switch header.type {
        case BoxType.handler:
            guard let codeString = payload?.fields.first(where: { $0.name == "handler_type" })?.value,
                  let code = try? FourCharCode(codeString) else { return }
            stack[stack.count - 1].handlerType = HandlerType(code: code)
        case BoxType.keys:
            if let table = payload?.metadataKeyTable {
                var mapping: [UInt32: ParsedBoxPayload.MetadataKeyTableBox.Entry] = [:]
                for entry in table.entries {
                    mapping[entry.index] = entry
                }
                stack[stack.count - 1].keyTable = mapping
            }
        default:
            break
        }
    }

    func environment(for header: BoxHeader) -> BoxParserRegistry.MetadataEnvironment {
        guard let context = stack.last else { return BoxParserRegistry.MetadataEnvironment() }
        switch header.type {
        case BoxType.metadata, BoxType.keys, BoxType.itemList:
            return BoxParserRegistry.MetadataEnvironment(
                handlerType: context.handlerType,
                keyTable: context.keyTable
            )
        default:
            return BoxParserRegistry.MetadataEnvironment()
        }
    }

    func didFinishBox(header: BoxHeader) {
        if header.type == BoxType.metadata {
            _ = stack.popLast()
        }
    }

    private enum BoxType {
        static let metadata = try! FourCharCode("meta")
        static let handler = try! FourCharCode("hdlr")
        static let keys = try! FourCharCode("keys")
        static let itemList = try! FourCharCode("ilst")
    }
}

private final class FragmentEnvironmentCoordinator: @unchecked Sendable {
    private struct FragmentContext {
        var header: ParsedBoxPayload.TrackFragmentHeaderBox?
        var decodeTime: ParsedBoxPayload.TrackFragmentDecodeTimeBox?
        var trackExtendsDefaults: ParsedBoxPayload.TrackExtendsDefaultsBox?
        var runs: [ParsedBoxPayload.TrackRunBox] = []
        var totalSampleCount: UInt64 = 0
        var totalSampleSize: UInt64? = 0
        var totalSampleDuration: UInt64? = 0
        var earliestPresentationTime: Int64?
        var latestPresentationTime: Int64?
        var firstDecodeTime: UInt64?
        var lastDecodeTime: UInt64?
        var baseDecodeTime: UInt64?
        var baseDecodeTimeIs64Bit = false
        var nextDecodeTime: UInt64?
        var dataCursor: UInt64?
        var runIndex: UInt32 = 0
        var nextSampleNumber: UInt64 = 1
        var sampleDescriptionIndex: UInt32? = 1
        var defaultSampleDuration: UInt32?
        var defaultSampleSize: UInt32?
        var defaultSampleFlags: UInt32?
        var baseDataOffset: UInt64?
        var trackID: UInt32?
        var moofStart: UInt64?
    }

    private var trackDefaults: [UInt32: ParsedBoxPayload.TrackExtendsDefaultsBox] = [:]
    private var fragmentStack: [FragmentContext] = []
    private var moofStack: [UInt64] = []

    func willStartBox(header: BoxHeader) {
        switch header.type {
        case BoxType.movieFragment:
            moofStack.append(UInt64(clamping: header.startOffset))
        case BoxType.trackFragment:
            var context = FragmentContext()
            context.moofStart = moofStack.last
            fragmentStack.append(context)
        default:
            break
        }
    }

    func didParsePayload(header: BoxHeader, payload: ParsedBoxPayload?) {
        switch header.type {
        case BoxType.trackExtends:
            if let defaults = payload?.trackExtends {
                trackDefaults[defaults.trackID] = defaults
            }
        case BoxType.trackFragmentHeader:
            guard let index = fragmentStack.indices.last,
                  let detail = payload?.trackFragmentHeader else { return }
            var context = fragmentStack[index]
            context.header = detail
            context.trackID = detail.trackID
            let defaults = trackDefaults[detail.trackID]
            context.trackExtendsDefaults = defaults
            let descriptionIndex = detail.sampleDescriptionIndex
                ?? defaults?.defaultSampleDescriptionIndex
                ?? context.sampleDescriptionIndex
                ?? 1
            context.sampleDescriptionIndex = descriptionIndex
            context.defaultSampleDuration = detail.defaultSampleDuration ?? defaults?.defaultSampleDuration
            context.defaultSampleSize = detail.defaultSampleSize ?? defaults?.defaultSampleSize
            context.defaultSampleFlags = detail.defaultSampleFlags ?? defaults?.defaultSampleFlags
            if let base = detail.baseDataOffset {
                context.baseDataOffset = base
                context.dataCursor = base
            } else if context.baseDataOffset == nil, detail.defaultBaseIsMoof, let moofStart = context.moofStart {
                context.baseDataOffset = moofStart
                if context.dataCursor == nil {
                    context.dataCursor = moofStart
                }
            }
            context.totalSampleCount = 0
            context.totalSampleSize = 0
            context.totalSampleDuration = 0
            context.runs.removeAll(keepingCapacity: true)
            context.runIndex = 0
            context.nextSampleNumber = 1
            fragmentStack[index] = context
        case BoxType.trackFragmentDecodeTime:
            guard let index = fragmentStack.indices.last,
                  let detail = payload?.trackFragmentDecodeTime else { return }
            var context = fragmentStack[index]
            context.decodeTime = detail
            context.baseDecodeTime = detail.baseMediaDecodeTime
            context.baseDecodeTimeIs64Bit = detail.baseMediaDecodeTimeIs64Bit
            context.nextDecodeTime = detail.baseMediaDecodeTime
            if context.firstDecodeTime == nil {
                context.firstDecodeTime = detail.baseMediaDecodeTime
            }
            fragmentStack[index] = context
        case BoxType.trackRun:
            guard let index = fragmentStack.indices.last,
                  let run = payload?.trackRun else { return }
            var context = fragmentStack[index]
            context.runs.append(run)
            let (newCount, overflowCount) = context.totalSampleCount.addingReportingOverflow(UInt64(run.sampleCount))
            context.totalSampleCount = overflowCount ? UInt64.max : newCount
            if context.totalSampleSize != nil {
                if let runTotalSize = run.totalSampleSize {
                    let (combined, overflow) = context.totalSampleSize!.addingReportingOverflow(runTotalSize)
                    context.totalSampleSize = overflow ? nil : combined
                } else {
                    context.totalSampleSize = nil
                }
            }
            if context.totalSampleDuration != nil {
                if let runTotalDuration = run.totalSampleDuration {
                    let (combined, overflow) = context.totalSampleDuration!.addingReportingOverflow(runTotalDuration)
                    context.totalSampleDuration = overflow ? nil : combined
                } else {
                    context.totalSampleDuration = nil
                }
            }
            if let startPresentation = run.startPresentationTime ?? int64(from: run.startDecodeTime) {
                if let current = context.earliestPresentationTime {
                    context.earliestPresentationTime = min(current, startPresentation)
                } else {
                    context.earliestPresentationTime = startPresentation
                }
            }
            if let endPresentation = run.endPresentationTime ?? int64(from: run.endDecodeTime) {
                if let current = context.latestPresentationTime {
                    context.latestPresentationTime = max(current, endPresentation)
                } else {
                    context.latestPresentationTime = endPresentation
                }
            }
            if context.firstDecodeTime == nil {
                context.firstDecodeTime = run.startDecodeTime ?? context.baseDecodeTime
            }
            if let endDecode = run.endDecodeTime {
                context.lastDecodeTime = endDecode
                context.nextDecodeTime = endDecode
            } else if let start = run.startDecodeTime, let total = run.totalSampleDuration {
                let (combined, overflow) = start.addingReportingOverflow(total)
                if !overflow {
                    context.lastDecodeTime = combined
                    context.nextDecodeTime = combined
                } else {
                    context.nextDecodeTime = nil
                }
            }
            if let endData = run.endDataOffset {
                context.dataCursor = endData
            } else {
                context.dataCursor = nil
            }
            let startIndex = run.firstSampleGlobalIndex ?? context.nextSampleNumber
            let (nextIndex, overflow) = startIndex.addingReportingOverflow(UInt64(run.sampleCount))
            context.nextSampleNumber = overflow ? startIndex : nextIndex
            context.runIndex &+= 1
            fragmentStack[index] = context
        default:
            break
        }
    }

    func environment(for header: BoxHeader) -> BoxParserRegistry.FragmentEnvironment {
        guard header.type == BoxType.trackRun,
              let index = fragmentStack.indices.last else {
            return BoxParserRegistry.FragmentEnvironment()
        }

        var context = fragmentStack[index]
        let defaults: ParsedBoxPayload.TrackExtendsDefaultsBox?
        if let trackID = context.trackID {
            defaults = context.trackExtendsDefaults ?? trackDefaults[trackID]
        } else {
            defaults = nil
        }

        if context.trackExtendsDefaults == nil, let defaults {
            context.trackExtendsDefaults = defaults
        }
        if context.sampleDescriptionIndex == nil {
            context.sampleDescriptionIndex = defaults?.defaultSampleDescriptionIndex ?? 1
        }
        if context.defaultSampleDuration == nil {
            context.defaultSampleDuration = defaults?.defaultSampleDuration
        }
        if context.defaultSampleSize == nil {
            context.defaultSampleSize = defaults?.defaultSampleSize
        }
        if context.defaultSampleFlags == nil {
            context.defaultSampleFlags = defaults?.defaultSampleFlags
        }
        if context.baseDataOffset == nil,
           context.header?.defaultBaseIsMoof == true,
           let moofStart = context.moofStart {
            context.baseDataOffset = moofStart
            if context.dataCursor == nil {
                context.dataCursor = moofStart
            }
        }
        if context.baseDecodeTime == nil {
            context.baseDecodeTime = context.decodeTime?.baseMediaDecodeTime
        }
        if context.nextDecodeTime == nil {
            context.nextDecodeTime = context.decodeTime?.baseMediaDecodeTime ?? context.baseDecodeTime
        }

        let environment = BoxParserRegistry.FragmentEnvironment(
            trackID: context.trackID,
            sampleDescriptionIndex: context.sampleDescriptionIndex,
            defaultSampleDuration: context.defaultSampleDuration,
            defaultSampleSize: context.defaultSampleSize,
            defaultSampleFlags: context.defaultSampleFlags,
            baseDataOffset: context.baseDataOffset,
            dataCursor: context.dataCursor,
            nextDecodeTime: context.nextDecodeTime,
            baseDecodeTime: context.baseDecodeTime,
            baseDecodeTimeIs64Bit: context.decodeTime?.baseMediaDecodeTimeIs64Bit ?? context.baseDecodeTimeIs64Bit,
            trackExtendsDefaults: context.trackExtendsDefaults ?? defaults,
            trackFragmentHeader: context.header,
            trackFragmentDecodeTime: context.decodeTime,
            runIndex: context.runIndex,
            nextSampleNumber: context.nextSampleNumber
        )

        fragmentStack[index] = context
        return environment
    }

    func didFinishBox(header: BoxHeader) -> ParsedBoxPayload? {
        switch header.type {
        case BoxType.trackFragment:
            guard let context = fragmentStack.popLast() else { return nil }
            let defaults = context.trackExtendsDefaults
                ?? context.trackID.flatMap { trackDefaults[$0] }
            let summary = ParsedBoxPayload.TrackFragmentBox(
                trackID: context.trackID ?? context.header?.trackID,
                sampleDescriptionIndex: context.sampleDescriptionIndex
                    ?? defaults?.defaultSampleDescriptionIndex
                    ?? 1,
                baseDataOffset: context.baseDataOffset,
                defaultSampleDuration: context.defaultSampleDuration ?? defaults?.defaultSampleDuration,
                defaultSampleSize: context.defaultSampleSize ?? defaults?.defaultSampleSize,
                defaultSampleFlags: context.defaultSampleFlags ?? defaults?.defaultSampleFlags,
                durationIsEmpty: context.header?.durationIsEmpty ?? false,
                defaultBaseIsMoof: context.header?.defaultBaseIsMoof ?? false,
                baseDecodeTime: context.decodeTime?.baseMediaDecodeTime ?? context.baseDecodeTime,
                baseDecodeTimeIs64Bit: context.decodeTime?.baseMediaDecodeTimeIs64Bit
                    ?? context.baseDecodeTimeIs64Bit,
                runs: context.runs,
                totalSampleCount: context.totalSampleCount,
                totalSampleSize: context.totalSampleSize,
                totalSampleDuration: context.totalSampleDuration,
                earliestPresentationTime: context.earliestPresentationTime,
                latestPresentationTime: context.latestPresentationTime,
                firstDecodeTime: context.firstDecodeTime ?? context.baseDecodeTime,
                lastDecodeTime: context.lastDecodeTime ?? context.nextDecodeTime ?? context.baseDecodeTime
            )
            return ParsedBoxPayload(detail: .trackFragment(summary))
        case BoxType.movieFragment:
            _ = moofStack.popLast()
        default:
            break
        }
        return nil
    }

    private func int64(from value: UInt64?) -> Int64? {
        guard let value, value <= UInt64(Int64.max) else { return nil }
        return Int64(value)
    }

    private enum BoxType {
        static let movieFragment = try! FourCharCode("moof")
        static let trackFragment = try! FourCharCode("traf")
        static let trackFragmentHeader = try! FourCharCode("tfhd")
        static let trackFragmentDecodeTime = try! FourCharCode("tfdt")
        static let trackRun = try! FourCharCode("trun")
        static let trackExtends = try! FourCharCode("trex")
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

private final class RandomAccessIndexCoordinator: @unchecked Sendable {
    private struct TrackFragmentRecord {
        var order: UInt32
        var detail: ParsedBoxPayload.TrackFragmentBox
    }

    private struct MoofContext {
        var startOffset: UInt64
        var sequenceNumber: UInt32?
        var trackFragments: [TrackFragmentRecord] = []
        var nextOrder: UInt32 = 1
    }

    private struct MfraContext {
        var trackTables: [ParsedBoxPayload.TrackFragmentRandomAccessBox] = []
        var offset: ParsedBoxPayload.MovieFragmentRandomAccessOffsetBox?
    }

    private var moofStack: [MoofContext] = []
    private var fragmentsByOffset: [UInt64: BoxParserRegistry.RandomAccessEnvironment.Fragment] = [:]
    private var mfraStack: [MfraContext] = []

    func willStartBox(header: BoxHeader) {
        switch header.type {
        case BoxType.movieFragment:
            let start = header.startOffset >= 0 ? UInt64(header.startOffset) : 0
            moofStack.append(MoofContext(startOffset: start))
        case BoxType.movieFragmentRandomAccess:
            mfraStack.append(MfraContext())
        default:
            break
        }
    }

    func didParsePayload(header: BoxHeader, payload: ParsedBoxPayload?) {
        switch header.type {
        case BoxType.movieFragmentHeader:
            if let index = moofStack.indices.last,
               let sequence = payload?.movieFragmentHeader?.sequenceNumber {
                moofStack[index].sequenceNumber = sequence
            }
        case BoxType.trackFragmentRandomAccess:
            if let index = mfraStack.indices.last,
               let table = payload?.trackFragmentRandomAccess {
                mfraStack[index].trackTables.append(table)
            }
        case BoxType.movieFragmentRandomAccessOffset:
            if let index = mfraStack.indices.last,
               let offset = payload?.movieFragmentRandomAccessOffset {
                mfraStack[index].offset = offset
            }
        default:
            break
        }
    }

    func didFinishBox(header: BoxHeader, payload: ParsedBoxPayload?) -> ParsedBoxPayload? {
        switch header.type {
        case BoxType.trackFragment:
            guard let index = moofStack.indices.last,
                  let summary = payload?.trackFragment else { return nil }
            var context = moofStack[index]
            context.trackFragments.append(TrackFragmentRecord(order: context.nextOrder, detail: summary))
            context.nextOrder &+= 1
            moofStack[index] = context
            return nil
        case BoxType.movieFragment:
            guard let context = moofStack.popLast() else { return nil }
            let trackFragments = context.trackFragments.map { record in
                BoxParserRegistry.RandomAccessEnvironment.TrackFragment(order: record.order, detail: record.detail)
            }
            let fragment = BoxParserRegistry.RandomAccessEnvironment.Fragment(
                sequenceNumber: context.sequenceNumber,
                trackFragments: trackFragments
            )
            fragmentsByOffset[context.startOffset] = fragment
            return nil
        case BoxType.movieFragmentRandomAccess:
            guard let context = mfraStack.popLast() else { return nil }
            let summaries: [ParsedBoxPayload.MovieFragmentRandomAccessBox.TrackSummary] = context.trackTables.map { table in
                let times = table.entries.map { $0.time }
                let earliest = times.min()
                let latest = times.max()
                let fragments = Array(Set(table.entries.compactMap { $0.fragmentSequenceNumber })).sorted()
                return ParsedBoxPayload.MovieFragmentRandomAccessBox.TrackSummary(
                    trackID: table.trackID,
                    entryCount: table.entries.count,
                    earliestTime: earliest,
                    latestTime: latest,
                    referencedFragmentSequenceNumbers: fragments
                )
            }
            let total = context.trackTables.reduce(0) { $0 + $1.entries.count }
            let detail = ParsedBoxPayload.MovieFragmentRandomAccessBox(
                tracks: summaries,
                totalEntryCount: total,
                offset: context.offset
            )
            return ParsedBoxPayload(detail: .movieFragmentRandomAccess(detail))
        default:
            return nil
        }
    }

    func environment(for header: BoxHeader) -> BoxParserRegistry.RandomAccessEnvironment {
        var mapping = fragmentsByOffset
        for context in moofStack {
            if mapping[context.startOffset] != nil { continue }
            let fragments = context.trackFragments.map { record in
                BoxParserRegistry.RandomAccessEnvironment.TrackFragment(order: record.order, detail: record.detail)
            }
            mapping[context.startOffset] = BoxParserRegistry.RandomAccessEnvironment.Fragment(
                sequenceNumber: context.sequenceNumber,
                trackFragments: fragments
            )
        }
        return BoxParserRegistry.RandomAccessEnvironment(fragmentsByMoofOffset: mapping)
    }

    private enum BoxType {
        static let movieFragment = try! FourCharCode("moof")
        static let trackFragment = try! FourCharCode("traf")
        static let movieFragmentHeader = try! FourCharCode("mfhd")
        static let movieFragmentRandomAccess = try! FourCharCode("mfra")
        static let trackFragmentRandomAccess = try! FourCharCode("tfra")
        static let movieFragmentRandomAccessOffset = try! FourCharCode("mfro")
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
                    let metadataCoordinator = MetadataEnvironmentCoordinator()
                    let fragmentCoordinator = FragmentEnvironmentCoordinator()
                    let randomAccessCoordinator = RandomAccessIndexCoordinator()
                    do {
                        try walker.walk(
                            reader: reader,
                            cancellationCheck: { try Task.checkCancellation() },
                            onEvent: { event in
                                let enriched: ParseEvent
                                switch event.kind {
                                case .willStartBox(let header, _):
                                    editListCoordinator.willStartBox(header: header)
                                    metadataCoordinator.willStartBox(header: header)
                                    fragmentCoordinator.willStartBox(header: header)
                                    randomAccessCoordinator.willStartBox(header: header)
                                    let descriptor = catalog.descriptor(for: header)
                                    metadataStack.append(descriptor)
                                    let payload = BoxParserRegistry.withEditListEnvironmentProvider({ request, _ in
                                        editListCoordinator.environment(for: request)
                                    }) {
                                        BoxParserRegistry.withMetadataEnvironmentProvider({ request, _ in
                                            metadataCoordinator.environment(for: request)
                                        }) {
                                            BoxParserRegistry.withFragmentEnvironmentProvider({ request, _ in
                                                fragmentCoordinator.environment(for: request)
                                            }) {
                                                BoxParserRegistry.withRandomAccessEnvironmentProvider({ request, _ in
                                                    randomAccessCoordinator.environment(for: request)
                                                }) {
                                                    ParsePipeline.parsePayload(
                                                        header: header,
                                                        reader: reader,
                                                        registry: registry,
                                                        logger: logger
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    editListCoordinator.didParsePayload(header: header, payload: payload)
                                    metadataCoordinator.didParsePayload(header: header, payload: payload)
                                    fragmentCoordinator.didParsePayload(header: header, payload: payload)
                                    randomAccessCoordinator.didParsePayload(header: header, payload: payload)
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
                                    let fragmentPayload = fragmentCoordinator.didFinishBox(header: header)
                                    let randomAccessPayload = randomAccessCoordinator.didFinishBox(
                                        header: header,
                                        payload: fragmentPayload
                                    )
                                    editListCoordinator.didFinishBox(header: header)
                                    metadataCoordinator.didFinishBox(header: header)
                                    enriched = ParseEvent(
                                        kind: event.kind,
                                        offset: event.offset,
                                        metadata: descriptor,
                                        payload: randomAccessPayload ?? fragmentPayload
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
