import Foundation

protocol BoxValidationRule: Sendable {
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue]
}

struct BoxValidator: Sendable {
    private let rules: [any BoxValidationRule]

    init(rules: [any BoxValidationRule] = BoxValidator.defaultRules) {
        self.rules = rules
    }

    func annotate(event: ParseEvent, reader: RandomAccessReader) -> ParseEvent {
        let issues = rules.flatMap { $0.issues(for: event, reader: reader) }
        guard !issues.isEmpty else {
            return event
        }
        return ParseEvent(
            kind: event.kind,
            offset: event.offset,
            metadata: event.metadata,
            payload: event.payload,
            validationIssues: issues
        )
    }
}

private extension BoxValidator {
    static var defaultRules: [any BoxValidationRule] {
        [
            StructuralSizeRule(),
            ContainerBoundaryRule(),
            FileTypeOrderingRule(),
            MovieDataOrderingRule(),
            TopLevelOrderingAdvisoryRule(),
            VersionFlagsRule(),
            EditListValidationRule(),
            SampleTableCorrelationRule(),
            CodecConfigurationValidationRule(),
            FragmentSequenceRule(),
            FragmentRunValidationRule(),
            UnknownBoxRule()
        ]
    }
}

private struct StructuralSizeRule: BoxValidationRule {
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }

        var issues: [ValidationIssue] = []
        if header.totalSize < header.headerSize {
            let message = "Box \(header.identifierString) declares total size \(header.totalSize) smaller than header length \(header.headerSize)."
            issues.append(ValidationIssue(ruleID: "VR-001", message: message, severity: .error))
        }

        if header.endOffset > reader.length {
            let message = "Box \(header.identifierString) extends beyond file length (declared end \(header.endOffset), file length \(reader.length))."
            issues.append(ValidationIssue(ruleID: "VR-001", message: message, severity: .error))
        }

        return issues
    }
}

private final class ContainerBoundaryRule: BoxValidationRule, @unchecked Sendable {
    private struct State {
        let header: BoxHeader
        var nextChildOffset: Int64
        var hasChildren: Bool
    }

    private var stack: [State] = []

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        switch event.kind {
        case let .willStartBox(header, depth):
            if stack.count > depth {
                stack.removeLast(stack.count - depth)
            }
            if stack.count < depth {
                let message = "Start event for \(header.identifierString) arrived at depth \(depth) without a matching parent context."
                issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
                stack.removeAll()
            }

            if let parentIndex = stack.indices.last {
                var parent = stack[parentIndex]
                if parent.nextChildOffset != header.startOffset {
                    let message = "Container \(parent.header.identifierString) expected child to start at offset \(parent.nextChildOffset) but found \(header.startOffset)."
                    issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
                    parent.nextChildOffset = header.startOffset
                }
                parent.nextChildOffset = header.endOffset
                parent.hasChildren = true
                stack[parentIndex] = parent
            }

            let childState = State(
                header: header,
                nextChildOffset: header.payloadRange.lowerBound,
                hasChildren: false
            )
            stack.append(childState)

        case let .didFinishBox(header, depth):
            if stack.count > depth + 1 {
                stack.removeLast(stack.count - (depth + 1))
            }
            guard stack.count >= depth + 1 else {
                let message = "Finish event for \(header.identifierString) arrived at depth \(depth) without an opening start event."
                issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
                stack.removeAll()
                return issues
            }

            let state = stack.removeLast()
            if state.header != header {
                let message = "Container stack mismatch: expected to finish \(state.header.identifierString) but received \(header.identifierString)."
                issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
            }

            if state.hasChildren {
                let expectedEnd = state.header.payloadRange.upperBound
                if state.nextChildOffset != expectedEnd {
                    let message = "Container \(state.header.identifierString) expected to close at offset \(expectedEnd) but consumed \(state.nextChildOffset)."
                    issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
                }
            }

            if let parentIndex = stack.indices.last {
                var parent = stack[parentIndex]
                parent.nextChildOffset = header.endOffset
                parent.hasChildren = true
                stack[parentIndex] = parent
            }
        }

        return issues
    }
}

private struct VersionFlagsRule: BoxValidationRule {
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }
        guard let descriptor = event.metadata else { return [] }
        guard descriptor.version != nil || descriptor.flags != nil else { return [] }

        let payloadRange = header.payloadRange
        guard payloadRange.count >= 4 else {
            return [ValidationIssue(
                ruleID: "VR-003",
                message: "\(header.identifierString) payload too small for version/flags check (expected 4 bytes, found \(payloadRange.count)).",
                severity: .warning
            )]
        }

        do {
            let data = try reader.read(at: payloadRange.lowerBound, count: 4)
            guard data.count == 4 else {
                return [ValidationIssue(
                    ruleID: "VR-003",
                    message: "\(header.identifierString) payload truncated during version/flags check (expected 4 bytes, found \(data.count)).",
                    severity: .warning
                )]
            }

            let actualVersion = Int(data[0])
            let actualFlags = data[1...3].reduce(UInt32(0)) { partial, byte in
                (partial << 8) | UInt32(byte)
            }

            var issues: [ValidationIssue] = []
            if let expectedVersion = descriptor.version, expectedVersion != actualVersion {
                issues.append(ValidationIssue(
                    ruleID: "VR-003",
                    message: "\(header.identifierString) version mismatch: expected \(expectedVersion) but found \(actualVersion).",
                    severity: .warning
                ))
            }
            if let expectedFlags = descriptor.flags, expectedFlags != actualFlags {
                issues.append(ValidationIssue(
                    ruleID: "VR-003",
                    message: "\(header.identifierString) flags mismatch: expected 0x\(expectedFlags.paddedHex(length: 6)) but found 0x\(actualFlags.paddedHex(length: 6))",
                    severity: .warning
                ))
            }
            return issues
        } catch {
            return [ValidationIssue(
                ruleID: "VR-003",
                message: "\(header.identifierString) failed to read version/flags: \(error)",
                severity: .warning
            )]
        }
    }
}

private final class EditListValidationRule: BoxValidationRule, @unchecked Sendable {
    private struct MediaHeader {
        let timescale: UInt32
        let duration: UInt64
    }

    private struct PendingMediaCheck {
        let editList: ParsedBoxPayload.EditListBox
    }

    private struct TrackContext {
        var trackHeader: ParsedBoxPayload.TrackHeaderBox?
        var mediaHeader: MediaHeader?
        var pendingMediaChecks: [PendingMediaCheck] = []
    }

    private var movieTimescale: UInt32?
    private var movieDuration: UInt64?
    private var trackStack: [TrackContext] = []

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        switch event.kind {
        case let .willStartBox(header, depth):
            trimStack(to: depth)
            if header.type == BoxType.track {
                trackStack.append(TrackContext())
                return []
            }

            if header.type == BoxType.movieHeader {
                if let detail = event.payload?.movieHeader {
                    movieTimescale = detail.timescale
                    movieDuration = detail.duration
                }
                return []
            }

            guard let trackIndex = trackStack.indices.last else { return [] }

            switch header.type {
            case BoxType.trackHeader:
                if let detail = event.payload?.trackHeader {
                    trackStack[trackIndex].trackHeader = detail
                }
                return []
            case BoxType.mediaHeader:
                return handleMediaHeader(event: event, trackIndex: trackIndex)
            case BoxType.editList:
                return handleEditList(event: event, trackIndex: trackIndex)
            default:
                return []
            }
        case let .didFinishBox(header, depth):
            trimStack(to: depth)
            if header.type == BoxType.track, !trackStack.isEmpty {
                trackStack.removeLast()
            }
            return []
        }
    }

    private func trimStack(to depth: Int) {
        if trackStack.count > depth {
            trackStack.removeLast(trackStack.count - depth)
        }
    }

    private func handleMediaHeader(event: ParseEvent, trackIndex: Int) -> [ValidationIssue] {
        guard let payload = event.payload else { return [] }
        guard let mediaHeader = parseMediaHeader(from: payload) else { return [] }

        trackStack[trackIndex].mediaHeader = mediaHeader

        var issues: [ValidationIssue] = []
        if !trackStack[trackIndex].pendingMediaChecks.isEmpty {
            let checks = trackStack[trackIndex].pendingMediaChecks
            trackStack[trackIndex].pendingMediaChecks.removeAll()
            for pending in checks {
                if let issue = mediaDurationIssue(
                    for: pending.editList,
                    mediaHeader: mediaHeader,
                    trackContext: trackStack[trackIndex]
                ) {
                    issues.append(issue)
                }
            }
        }

        return issues
    }

    private func handleEditList(event: ParseEvent, trackIndex: Int) -> [ValidationIssue] {
        guard let editList = event.payload?.editList else { return [] }
        var issues: [ValidationIssue] = []
        let context = trackStack[trackIndex]

        if let movieIssue = movieDurationIssue(for: editList, trackContext: context) {
            issues.append(movieIssue)
        }

        if let trackIssue = trackDurationIssue(for: editList, trackContext: context) {
            issues.append(trackIssue)
        }

        if let mediaHeader = context.mediaHeader {
            if let issue = mediaDurationIssue(
                for: editList,
                mediaHeader: mediaHeader,
                trackContext: context
            ) {
                issues.append(issue)
            }
        } else {
            trackStack[trackIndex].pendingMediaChecks.append(PendingMediaCheck(editList: editList))
        }

        issues.append(contentsOf: rateIssues(for: editList, trackContext: context))

        return issues
    }

    private func movieDurationIssue(
        for editList: ParsedBoxPayload.EditListBox,
        trackContext: TrackContext
    ) -> ValidationIssue? {
        guard let movieTimescale = editList.movieTimescale ?? movieTimescale,
              movieTimescale > 0,
              let movieDuration = movieDuration else {
            return nil
        }

        let total = editList.entries.reduce(UInt64(0)) { $0 &+ $1.segmentDuration }
        let tolerance = UInt64(1)

        if total + tolerance < movieDuration {
            let diff = movieDuration - total
            return ValidationIssue(
                ruleID: "VR-014",
                message: "\(trackDescription(for: trackContext)) edit list spans \(total) movie ticks but movie header duration is \(movieDuration) (short by \(diff) > 1 tick).",
                severity: .warning
            )
        } else if total > movieDuration + tolerance {
            let diff = total - movieDuration
            return ValidationIssue(
                ruleID: "VR-014",
                message: "\(trackDescription(for: trackContext)) edit list spans \(total) movie ticks but movie header duration is \(movieDuration) (over by \(diff) > 1 tick).",
                severity: .warning
            )
        }

        return nil
    }

    private func trackDurationIssue(
        for editList: ParsedBoxPayload.EditListBox,
        trackContext: TrackContext
    ) -> ValidationIssue? {
        guard let trackHeader = trackContext.trackHeader, trackHeader.isEnabled else { return nil }
        let total = editList.entries.reduce(UInt64(0)) { $0 &+ $1.segmentDuration }
        let tolerance = UInt64(1)
        let declared = trackHeader.duration

        if total + tolerance < declared {
            let diff = declared - total
            return ValidationIssue(
                ruleID: "VR-014",
                message: "\(trackDescription(for: trackContext, trackHeader: trackHeader)) edit list spans \(total) movie ticks but track header duration is \(declared) (short by \(diff) > 1 tick).",
                severity: .warning
            )
        } else if total > declared + tolerance {
            let diff = total - declared
            return ValidationIssue(
                ruleID: "VR-014",
                message: "\(trackDescription(for: trackContext, trackHeader: trackHeader)) edit list spans \(total) movie ticks but track header duration is \(declared) (over by \(diff) > 1 tick).",
                severity: .warning
            )
        }

        return nil
    }

    private func mediaDurationIssue(
        for editList: ParsedBoxPayload.EditListBox,
        mediaHeader: MediaHeader,
        trackContext: TrackContext
    ) -> ValidationIssue? {
        guard let movieTimescale = editList.movieTimescale ?? movieTimescale,
              movieTimescale > 0,
              mediaHeader.timescale > 0 else {
            return nil
        }

        if let trackHeader = trackContext.trackHeader, !trackHeader.isEnabled {
            return nil
        }

        guard let expected = expectedMediaDuration(
            for: editList,
            movieTimescale: movieTimescale,
            mediaTimescale: mediaHeader.timescale
        ) else {
            return nil
        }

        let tolerance = UInt64(1)
        if expected + tolerance < mediaHeader.duration {
            let diff = mediaHeader.duration - expected
            return ValidationIssue(
                ruleID: "VR-014",
                message: "\(trackDescription(for: trackContext)) edit list consumes \(expected) media ticks but media duration is \(mediaHeader.duration) (short by \(diff) > 1 tick).",
                severity: .warning
            )
        } else if expected > mediaHeader.duration + tolerance {
            let diff = expected - mediaHeader.duration
            return ValidationIssue(
                ruleID: "VR-014",
                message: "\(trackDescription(for: trackContext)) edit list consumes \(expected) media ticks but media duration is \(mediaHeader.duration) (over by \(diff) > 1 tick).",
                severity: .warning
            )
        }

        return nil
    }

    private func rateIssues(
        for editList: ParsedBoxPayload.EditListBox,
        trackContext: TrackContext
    ) -> [ValidationIssue] {
        editList.entries.enumerated().compactMap { index, entry in
            if entry.mediaRateFraction != 0 {
                return ValidationIssue(
                    ruleID: "VR-014",
                    message: "\(trackDescription(for: trackContext)) edit list entry \(index) sets media_rate_fraction=\(entry.mediaRateFraction); fractional playback rates are unsupported.",
                    severity: .warning
                )
            }

            if entry.mediaRateInteger < 0 {
                return ValidationIssue(
                    ruleID: "VR-014",
                    message: "\(trackDescription(for: trackContext)) edit list entry \(index) uses media_rate_integer=\(entry.mediaRateInteger); reverse playback is unsupported.",
                    severity: .warning
                )
            }

            if entry.mediaRateInteger > 1 {
                return ValidationIssue(
                    ruleID: "VR-014",
                    message: "\(trackDescription(for: trackContext)) edit list entry \(index) uses media_rate_integer=\(entry.mediaRateInteger); playback rate adjustments above 1x are unsupported.",
                    severity: .warning
                )
            }

            return nil
        }
    }

    private func expectedMediaDuration(
        for editList: ParsedBoxPayload.EditListBox,
        movieTimescale: UInt32,
        mediaTimescale: UInt32
    ) -> UInt64? {
        guard movieTimescale > 0, mediaTimescale > 0 else { return nil }

        var total = Decimal(0)
        let movieScale = Decimal(movieTimescale)
        let mediaScale = Decimal(mediaTimescale)

        for entry in editList.entries where !entry.isEmptyEdit {
            let segment = Decimal(entry.segmentDuration)
            total += (segment * mediaScale) / movieScale
        }

        var rounded = total
        var result = Decimal()
        NSDecimalRound(&result, &rounded, 0, .plain)
        let number = NSDecimalNumber(decimal: result)
        return number.uint64Value
    }

    private func parseMediaHeader(from payload: ParsedBoxPayload) -> MediaHeader? {
        guard let timescaleValue = payload.fields.first(where: { $0.name == "timescale" })?.value,
              let timescale = UInt32(timescaleValue),
              let durationValue = payload.fields.first(where: { $0.name == "duration" })?.value,
              let duration = UInt64(durationValue) else {
            return nil
        }

        return MediaHeader(timescale: timescale, duration: duration)
    }

    private func trackDescription(
        for context: TrackContext,
        trackHeader: ParsedBoxPayload.TrackHeaderBox? = nil
    ) -> String {
        let header = trackHeader ?? context.trackHeader
        if let trackID = header?.trackID {
            return "Track \(trackID)"
        }
        return "Track"
    }

    private enum BoxType {
        static let movieHeader = try! FourCharCode("mvhd")
        static let track = try! FourCharCode("trak")
        static let trackHeader = try! FourCharCode("tkhd")
        static let mediaHeader = try! FourCharCode("mdhd")
        static let editList = try! FourCharCode("elst")
    }
}

private final class SampleTableCorrelationRule: BoxValidationRule, @unchecked Sendable {
    private struct SampleToChunkState {
        let identifier: String
        let box: ParsedBoxPayload.SampleToChunkBox
    }

    private struct SampleSizeState {
        let identifier: String
        let sampleCount: UInt32
    }

    private struct ChunkOffsetState {
        let identifier: String
        let entries: [ParsedBoxPayload.ChunkOffsetBox.Entry]
    }

    private struct TimeToSampleState {
        let identifier: String
        let totalSamples: UInt64
    }

    private struct CompositionOffsetState {
        let identifier: String
        let totalSamples: UInt64
    }

    private struct TrackContext {
        var trackHeader: ParsedBoxPayload.TrackHeaderBox?
        var sampleToChunk: SampleToChunkState?
        var sampleSize: SampleSizeState?
        var chunkOffsets: ChunkOffsetState?
        var timeToSample: TimeToSampleState?
        var compositionOffset: CompositionOffsetState?
    }

    private var trackStack: [TrackContext] = []

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        switch event.kind {
        case let .willStartBox(header, depth):
            trimStack(to: depth)

            if header.type == BoxType.track {
                trackStack.append(TrackContext())
                return []
            }

            guard let trackIndex = trackStack.indices.last else { return [] }

            switch header.type {
            case BoxType.trackHeader:
                if let detail = event.payload?.trackHeader {
                    trackStack[trackIndex].trackHeader = detail
                }
                return []
            case BoxType.sampleToChunk:
                guard let box = event.payload?.sampleToChunk else { return [] }
                trackStack[trackIndex].sampleToChunk = SampleToChunkState(
                    identifier: header.identifierString,
                    box: box
                )
                return evaluateTrack(for: trackIndex, triggeredKind: .sampleToChunk)
            case BoxType.sampleSize:
                guard let box = event.payload?.sampleSize else { return [] }
                trackStack[trackIndex].sampleSize = SampleSizeState(
                    identifier: header.identifierString,
                    sampleCount: box.sampleCount
                )
                return evaluateTrack(for: trackIndex, triggeredKind: .sampleSize)
            case BoxType.compactSampleSize:
                guard let box = event.payload?.compactSampleSize else { return [] }
                trackStack[trackIndex].sampleSize = SampleSizeState(
                    identifier: header.identifierString,
                    sampleCount: box.sampleCount
                )
                return evaluateTrack(for: trackIndex, triggeredKind: .sampleSize)
            case BoxType.chunkOffset32, BoxType.chunkOffset64:
                guard let box = event.payload?.chunkOffset else { return [] }
                trackStack[trackIndex].chunkOffsets = ChunkOffsetState(
                    identifier: header.identifierString,
                    entries: box.entries
                )
                var issues = chunkOffsetOrderingIssues(
                    entries: box.entries,
                    trackIndex: trackIndex,
                    header: header
                )
                issues.append(contentsOf: evaluateTrack(for: trackIndex, triggeredKind: .chunkOffsets))
                return issues
            case BoxType.decodingTimeToSample:
                guard let box = event.payload?.decodingTimeToSample else { return [] }
                trackStack[trackIndex].timeToSample = TimeToSampleState(
                    identifier: header.identifierString,
                    totalSamples: totalSampleCount(box.entries.map { $0.sampleCount })
                )
                return evaluateTrack(for: trackIndex, triggeredKind: .timeToSample)
            case BoxType.compositionOffset:
                guard let box = event.payload?.compositionOffset else { return [] }
                trackStack[trackIndex].compositionOffset = CompositionOffsetState(
                    identifier: header.identifierString,
                    totalSamples: totalSampleCount(box.entries.map { $0.sampleCount })
                )
                return evaluateTrack(for: trackIndex, triggeredKind: .compositionOffset)
            default:
                return []
            }
        case let .didFinishBox(header, depth):
            trimStack(to: depth)
            if header.type == BoxType.track, !trackStack.isEmpty {
                trackStack.removeLast()
            }
            return []
        }
    }

    private func trimStack(to depth: Int) {
        if trackStack.count > depth {
            trackStack.removeLast(trackStack.count - depth)
        }
    }

    private func evaluateTrack(for trackIndex: Int, triggeredKind: SampleTableKind) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        switch triggeredKind {
        case .chunkOffsets, .sampleToChunk, .sampleSize:
            issues.append(contentsOf: chunkCorrelationIssues(for: trackIndex))
        case .timeToSample, .compositionOffset:
            break
        }
        issues.append(contentsOf: sampleCountConsistencyIssues(for: trackIndex, triggeredKind: triggeredKind))
        return issues
    }

    private func chunkCorrelationIssues(for trackIndex: Int) -> [ValidationIssue] {
        let context = trackStack[trackIndex]
        guard let sampleToChunk = context.sampleToChunk,
              let sampleSize = context.sampleSize,
              let chunkOffsets = context.chunkOffsets else {
            return []
        }

        let chunkCount = chunkOffsets.entries.count
        let declaredSamples = UInt64(sampleSize.sampleCount)
        let trackLabel = trackDescription(for: context)
        var issues: [ValidationIssue] = []

        if chunkCount == 0 {
            if declaredSamples > 0 {
                issues.append(ValidationIssue(
                    ruleID: "VR-015",
                    message: "\(trackLabel) chunk offset table \(chunkOffsets.identifier) declares 0 chunks but sample size table \(sampleSize.identifier) declares \(declaredSamples) samples.",
                    severity: .error
                ))
            }
            return issues
        }

        let entries = sampleToChunk.box.entries
        if entries.isEmpty {
            if declaredSamples > 0 {
                issues.append(ValidationIssue(
                    ruleID: "VR-015",
                    message: "\(trackLabel) sample-to-chunk table \(sampleToChunk.identifier) contains no entries but chunk offset table \(chunkOffsets.identifier) defines \(chunkCount) chunks.",
                    severity: .error
                ))
            }
            return issues
        }

        var sortedEntries = entries
        sortedEntries.sort { $0.firstChunk < $1.firstChunk }

        var coverage = 0
        var totalSamples = UInt64(0)

        for (index, entry) in sortedEntries.enumerated() {
            let start = Int(entry.firstChunk)
            if start < 1 {
                issues.append(ValidationIssue(
                    ruleID: "VR-015",
                    message: "\(trackLabel) sample-to-chunk table \(sampleToChunk.identifier) has entry \(index + 1) with invalid first_chunk \(entry.firstChunk).",
                    severity: .error
                ))
                continue
            }

            if start > chunkCount {
                issues.append(ValidationIssue(
                    ruleID: "VR-015",
                    message: "\(trackLabel) sample-to-chunk table \(sampleToChunk.identifier) references chunk \(entry.firstChunk) but chunk offset table \(chunkOffsets.identifier) only defines \(chunkCount) chunks.",
                    severity: .error
                ))
                continue
            }

            if index + 1 < sortedEntries.count,
               sortedEntries[index + 1].firstChunk <= entry.firstChunk {
                issues.append(ValidationIssue(
                    ruleID: "VR-015",
                    message: "\(trackLabel) sample-to-chunk table \(sampleToChunk.identifier) has non-monotonic first_chunk values at entries \(index + 1) and \(index + 2).",
                    severity: .error
                ))
            }

            let nextStart = index + 1 < sortedEntries.count
                ? Int(sortedEntries[index + 1].firstChunk)
                : chunkCount + 1
            let runEnd = min(nextStart, chunkCount + 1)

            if runEnd <= start {
                continue
            }

            let runLength = runEnd - start
            coverage += runLength
            totalSamples += UInt64(runLength) * UInt64(entry.samplesPerChunk)
        }

        if coverage < chunkCount {
            let missing = chunkCount - coverage
            issues.append(ValidationIssue(
                ruleID: "VR-015",
                message: "\(trackLabel) sample-to-chunk table \(sampleToChunk.identifier) only covers \(coverage) of \(chunkCount) chunks declared by \(chunkOffsets.identifier) (missing \(missing)).",
                severity: .error
            ))
        }

        if totalSamples != declaredSamples {
            issues.append(ValidationIssue(
                ruleID: "VR-015",
                message: "\(trackLabel) sample size table \(sampleSize.identifier) declares \(declaredSamples) samples but sample-to-chunk table \(sampleToChunk.identifier) expands to \(totalSamples) samples across \(chunkCount) chunks.",
                severity: .error
            ))
        }

        return issues
    }

    private func sampleCountConsistencyIssues(for trackIndex: Int, triggeredKind: SampleTableKind) -> [ValidationIssue] {
        let context = trackStack[trackIndex]
        let trackLabel = trackDescription(for: context)
        var issues: [ValidationIssue] = []

        if triggeredKind == .sampleSize || triggeredKind == .timeToSample,
           let sampleSize = context.sampleSize,
           let timeToSample = context.timeToSample {
            let declared = UInt64(sampleSize.sampleCount)
            if timeToSample.totalSamples != declared {
                issues.append(ValidationIssue(
                    ruleID: "VR-015",
                    message: "\(trackLabel) time-to-sample table \(timeToSample.identifier) sums to \(timeToSample.totalSamples) samples but sample size table \(sampleSize.identifier) declares \(declared) samples.",
                    severity: .error
                ))
            }
        }

        if triggeredKind == .sampleSize || triggeredKind == .compositionOffset,
           let sampleSize = context.sampleSize,
           let composition = context.compositionOffset {
            let declared = UInt64(sampleSize.sampleCount)
            if composition.totalSamples != declared {
                issues.append(ValidationIssue(
                    ruleID: "VR-015",
                    message: "\(trackLabel) composition offset table \(composition.identifier) sums to \(composition.totalSamples) samples but sample size table \(sampleSize.identifier) declares \(declared) samples.",
                    severity: .error
                ))
            }
        }

        if triggeredKind == .timeToSample || triggeredKind == .compositionOffset,
           let timeToSample = context.timeToSample,
           let composition = context.compositionOffset,
           timeToSample.totalSamples != composition.totalSamples {
            issues.append(ValidationIssue(
                ruleID: "VR-015",
                message: "\(trackLabel) time-to-sample table \(timeToSample.identifier) sums to \(timeToSample.totalSamples) samples but composition offset table \(composition.identifier) covers \(composition.totalSamples) samples.",
                severity: .error
            ))
        }

        return issues
    }

    private func totalSampleCount<S: Sequence>(_ counts: S) -> UInt64 where S.Element == UInt32 {
        counts.reduce(UInt64(0)) { total, value in
            let (next, overflow) = total.addingReportingOverflow(UInt64(value))
            return overflow ? UInt64.max : next
        }
    }

    private enum SampleTableKind {
        case sampleToChunk
        case sampleSize
        case chunkOffsets
        case timeToSample
        case compositionOffset
    }

    private func chunkOffsetOrderingIssues(
        entries: [ParsedBoxPayload.ChunkOffsetBox.Entry],
        trackIndex: Int,
        header: BoxHeader
    ) -> [ValidationIssue] {
        guard entries.count >= 2 else { return [] }
        let context = trackStack[trackIndex]
        let label = trackDescription(for: context)

        for index in entries.indices.dropFirst() {
            let previous = entries[index - 1]
            let current = entries[index]
            if current.offset <= previous.offset {
                let message = "\(label) chunk offset table \(header.identifierString) has non-monotonic offsets at entries \(previous.index) and \(current.index) (\(previous.offset) then \(current.offset))."
                return [ValidationIssue(ruleID: "VR-015", message: message, severity: .error)]
            }
        }

        return []
    }

    private func trackDescription(for context: TrackContext) -> String {
        if let trackID = context.trackHeader?.trackID {
            return "Track \(trackID)"
        }
        return "Track"
    }

    private enum BoxType {
        static let track = try! FourCharCode("trak")
        static let trackHeader = try! FourCharCode("tkhd")
        static let sampleToChunk = try! FourCharCode("stsc")
        static let sampleSize = try! FourCharCode("stsz")
        static let compactSampleSize = try! FourCharCode("stz2")
        static let chunkOffset32 = try! FourCharCode("stco")
        static let chunkOffset64 = try! FourCharCode("co64")
        static let decodingTimeToSample = try! FourCharCode("stts")
        static let compositionOffset = try! FourCharCode("ctts")
    }
}

private final class CodecConfigurationValidationRule: BoxValidationRule, @unchecked Sendable {
    private struct TrackContext {
        var trackHeader: ParsedBoxPayload.TrackHeaderBox?
    }

    private struct SampleEntry {
        let index: Int
        let format: FourCharCode
        let effectiveFormat: FourCharCode
        let nestedBoxes: [BoxParserRegistry.DefaultParsers.NestedBox]
    }

    private var trackStack: [TrackContext] = []

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        switch event.kind {
        case let .willStartBox(header, depth):
            trimStack(to: depth)

            if header.type == BoxType.track {
                trackStack.append(TrackContext())
                return []
            }

            if let trackIndex = trackStack.indices.last, header.type == BoxType.trackHeader {
                if let detail = event.payload?.trackHeader {
                    trackStack[trackIndex].trackHeader = detail
                }
                return []
            }

            if header.type == BoxType.sampleDescription {
                return sampleDescriptionIssues(
                    header: header,
                    reader: reader,
                    trackContext: trackStack.last
                )
            }

            return []

        case let .didFinishBox(header, depth):
            trimStack(to: depth)
            if header.type == BoxType.track, !trackStack.isEmpty {
                trackStack.removeLast()
            }
            return []
        }
    }

    private func trimStack(to depth: Int) {
        if trackStack.count > depth {
            trackStack.removeLast(trackStack.count - depth)
        }
    }

    private func sampleDescriptionIssues(
        header: BoxHeader,
        reader: RandomAccessReader,
        trackContext: TrackContext?
    ) -> [ValidationIssue] {
        let entries = sampleEntries(for: header, reader: reader)
        guard !entries.isEmpty else { return [] }

        var issues: [ValidationIssue] = []
        let trackLabel = trackDescription(for: trackContext)

        for entry in entries {
            let prefix = entryPrefix(
                trackLabel: trackLabel,
                entryIndex: entry.index,
                format: entry.effectiveFormat
            )

            if BoxParserRegistry.DefaultParsers.avcSampleEntryTypes.contains(entry.effectiveFormat) {
                for box in entry.nestedBoxes where box.type.rawValue == "avcC" {
                    issues.append(contentsOf: avcIssues(prefix: prefix, box: box, reader: reader))
                }
            }

            if BoxParserRegistry.DefaultParsers.hevcSampleEntryTypes.contains(entry.effectiveFormat) {
                for box in entry.nestedBoxes where box.type.rawValue == "hvcC" {
                    issues.append(contentsOf: hevcIssues(prefix: prefix, box: box, reader: reader))
                }
            }
        }

        return issues
    }

    private func trackDescription(for context: TrackContext?) -> String {
        if let trackID = context?.trackHeader?.trackID {
            return "Track \(trackID)"
        }
        return "Track"
    }

    private func entryPrefix(
        trackLabel: String,
        entryIndex: Int,
        format: FourCharCode
    ) -> String {
        "\(trackLabel) sample description entry \(entryIndex) (format \(format.rawValue))"
    }

    private func sampleEntries(for header: BoxHeader, reader: RandomAccessReader) -> [SampleEntry] {
        let payloadStart = header.payloadRange.lowerBound
        let payloadEnd = header.payloadRange.upperBound
        guard payloadEnd > payloadStart else { return [] }

        var cursor = payloadStart
        guard cursor + 8 <= payloadEnd else { return [] }
        cursor += 4

        guard let entryCountValue = try? BoxParserRegistry.DefaultParsers.readUInt32(
            reader,
            at: cursor,
            end: payloadEnd
        ) else { return [] }
        let entryCount = Int(entryCountValue)
        cursor += 4

        var entries: [SampleEntry] = []
        var index = 0

        while index < entryCount, cursor + 8 <= payloadEnd {
            guard let declaredSizeValue = try? BoxParserRegistry.DefaultParsers.readUInt32(
                reader,
                at: cursor,
                end: payloadEnd
            ), let format = try? BoxParserRegistry.DefaultParsers.readFourCC(
                reader,
                at: cursor + 4,
                end: payloadEnd
            ) else {
                break
            }

            var headerLength: Int64 = 8
            var entryLength: Int64?
            switch declaredSizeValue {
            case 0:
                entryLength = payloadEnd - cursor
            case 1:
                guard let largeSize = try? BoxParserRegistry.DefaultParsers.readUInt64(
                    reader,
                    at: cursor + 8,
                    end: payloadEnd
                ), let converted = Int64(exactly: largeSize) else {
                    break
                }
                headerLength = 16
                entryLength = converted
            default:
                entryLength = Int64(declaredSizeValue)
            }

            guard let resolvedLength = entryLength, resolvedLength >= headerLength else { break }
            let entryEnd = cursor + resolvedLength
            guard entryEnd <= payloadEnd, entryEnd > cursor else { break }

            let contentStart = cursor + headerLength

            var nestedBoxes: [BoxParserRegistry.DefaultParsers.NestedBox] = []
            if let baseHeaderLength = BoxParserRegistry.DefaultParsers.sampleEntryHeaderLength(for: format) {
                nestedBoxes = BoxParserRegistry.DefaultParsers.parseChildBoxes(
                    reader: reader,
                    contentStart: contentStart,
                    entryEnd: entryEnd,
                    baseHeaderLength: baseHeaderLength
                )
            }

            var effectiveFormat = format
            if format.rawValue == "encv" || format.rawValue == "enca" {
                let protection = BoxParserRegistry.DefaultParsers.parseProtectedSampleEntry(
                    reader: reader,
                    boxes: nestedBoxes,
                    entryIndex: index
                )
                if let original = protection.originalFormat {
                    effectiveFormat = original
                }
            }

            entries.append(SampleEntry(
                index: index,
                format: format,
                effectiveFormat: effectiveFormat,
                nestedBoxes: nestedBoxes
            ))

            cursor = entryEnd
            index += 1
        }

        return entries
    }

    private func avcIssues(
        prefix: String,
        box: BoxParserRegistry.DefaultParsers.NestedBox,
        reader: RandomAccessReader
    ) -> [ValidationIssue] {
        guard let data = readData(for: box, reader: reader) else {
            return [ValidationIssue(
                ruleID: "VR-018",
                message: "\(prefix) avcC payload truncated; unable to read configuration bytes.",
                severity: .error
            )]
        }

        if data.count < 5 {
            return [ValidationIssue(
                ruleID: "VR-018",
                message: "\(prefix) avcC missing length_size_minus_one field (payload \(data.count) bytes).",
                severity: .error
            )]
        }

        var issues: [ValidationIssue] = []

        let lengthSizeMinusOne = Int(data[4] & 0x03)
        let nalLengthBytes = lengthSizeMinusOne + 1
        if !(1...4).contains(nalLengthBytes) {
            issues.append(ValidationIssue(
                ruleID: "VR-018",
                message: "\(prefix) avcC declares \(nalLengthBytes)-byte NAL unit lengths; expected 1-4 bytes.",
                severity: .error
            ))
        }

        guard data.count >= 6 else { return issues }
        let declaredSps = Int(data[5] & 0x1F)
        var offset = 6

        for spsIndex in 0..<declaredSps {
            guard offset + 2 <= data.count else {
                issues.append(ValidationIssue(
                    ruleID: "VR-018",
                    message: "\(prefix) avcC declares \(declaredSps) sequence parameter sets but payload only provides \(spsIndex) before the length field for entry #\(spsIndex).",
                    severity: .error
                ))
                return issues
            }

            let length = Int(data[offset]) << 8 | Int(data[offset + 1])
            offset += 2

            if length == 0 {
                issues.append(ValidationIssue(
                    ruleID: "VR-018",
                    message: "\(prefix) avcC sequence parameter set #\(spsIndex) has zero length.",
                    severity: .error
                ))
                continue
            }

            guard offset + length <= data.count else {
                let remaining = data.count - offset
                issues.append(ValidationIssue(
                    ruleID: "VR-018",
                    message: "\(prefix) avcC declares \(declaredSps) sequence parameter sets but entry #\(spsIndex) length \(length) exceeds remaining payload (\(remaining) bytes).",
                    severity: .error
                ))
                return issues
            }

            offset += length
        }

        guard offset < data.count else {
            if declaredSps > 0 {
                issues.append(ValidationIssue(
                    ruleID: "VR-018",
                    message: "\(prefix) avcC declares \(declaredSps) sequence parameter sets but payload omits picture parameter set count.",
                    severity: .error
                ))
            }
            return issues
        }

        let declaredPps = Int(data[offset])
        offset += 1

        for ppsIndex in 0..<declaredPps {
            guard offset + 2 <= data.count else {
                issues.append(ValidationIssue(
                    ruleID: "VR-018",
                    message: "\(prefix) avcC declares \(declaredPps) picture parameter sets but payload only provides \(ppsIndex) before the length field for entry #\(ppsIndex).",
                    severity: .error
                ))
                return issues
            }

            let length = Int(data[offset]) << 8 | Int(data[offset + 1])
            offset += 2

            if length == 0 {
                issues.append(ValidationIssue(
                    ruleID: "VR-018",
                    message: "\(prefix) avcC picture parameter set #\(ppsIndex) has zero length.",
                    severity: .error
                ))
                continue
            }

            guard offset + length <= data.count else {
                let remaining = data.count - offset
                issues.append(ValidationIssue(
                    ruleID: "VR-018",
                    message: "\(prefix) avcC declares \(declaredPps) picture parameter sets but entry #\(ppsIndex) length \(length) exceeds remaining payload (\(remaining) bytes).",
                    severity: .error
                ))
                return issues
            }

            offset += length
        }

        return issues
    }

    private func hevcIssues(
        prefix: String,
        box: BoxParserRegistry.DefaultParsers.NestedBox,
        reader: RandomAccessReader
    ) -> [ValidationIssue] {
        guard let data = readData(for: box, reader: reader) else {
            return [ValidationIssue(
                ruleID: "VR-018",
                message: "\(prefix) hvcC payload truncated; unable to read configuration bytes.",
                severity: .error
            )]
        }

        if data.count < 23 {
            return [ValidationIssue(
                ruleID: "VR-018",
                message: "\(prefix) hvcC missing length_size_minus_one field (payload \(data.count) bytes).",
                severity: .error
            )]
        }

        var issues: [ValidationIssue] = []

        let lengthSizeMinusOne = Int(data[21] & 0x03)
        let nalLengthBytes = lengthSizeMinusOne + 1
        if !(1...4).contains(nalLengthBytes) {
            issues.append(ValidationIssue(
                ruleID: "VR-018",
                message: "\(prefix) hvcC declares \(nalLengthBytes)-byte NAL unit lengths; expected 1-4 bytes.",
                severity: .error
            ))
        }

        let declaredArrays = Int(data[22])
        var offset = 23

        for arrayIndex in 0..<declaredArrays {
            guard offset + 3 <= data.count else {
                issues.append(ValidationIssue(
                    ruleID: "VR-018",
                    message: "\(prefix) hvcC declares \(declaredArrays) NAL arrays but payload only provides \(arrayIndex) before array #\(arrayIndex) header.",
                    severity: .error
                ))
                return issues
            }

            let headerByte = data[offset]
            let nalType = headerByte & 0x3F
            let declaredNalus = Int(data[offset + 1]) << 8 | Int(data[offset + 2])
            offset += 3

            for nalIndex in 0..<declaredNalus {
                guard offset + 2 <= data.count else {
                    issues.append(ValidationIssue(
                        ruleID: "VR-018",
                        message: "\(prefix) hvcC NAL array (type \(nalTypeName(nalType))) declares \(declaredNalus) NAL units but payload only provides \(nalIndex) before the length field for entry #\(nalIndex).",
                        severity: .error
                    ))
                    return issues
                }

                let length = Int(data[offset]) << 8 | Int(data[offset + 1])
                offset += 2

                if length == 0 {
                    issues.append(ValidationIssue(
                        ruleID: "VR-018",
                        message: "\(prefix) hvcC \(nalTypeName(nalType)) NAL #\(nalIndex) has zero length.",
                        severity: .error
                    ))
                    continue
                }

                guard offset + length <= data.count else {
                    let remaining = data.count - offset
                    issues.append(ValidationIssue(
                        ruleID: "VR-018",
                        message: "\(prefix) hvcC NAL array (type \(nalTypeName(nalType))) declares \(declaredNalus) NAL units but entry #\(nalIndex) length \(length) exceeds remaining payload (\(remaining) bytes).",
                        severity: .error
                    ))
                    return issues
                }

                offset += length
            }
        }

        return issues
    }

    private func readData(
        for box: BoxParserRegistry.DefaultParsers.NestedBox,
        reader: RandomAccessReader
    ) -> Data? {
        let count64 = box.payloadRange.upperBound - box.payloadRange.lowerBound
        guard count64 > 0, count64 <= Int64(Int.max) else { return nil }
        let count = Int(count64)
        do {
            return try BoxParserRegistry.DefaultParsers.readData(
                reader,
                at: box.payloadRange.lowerBound,
                count: count,
                end: box.payloadRange.upperBound
            )
        } catch {
            return nil
        }
    }

    private func nalTypeName(_ type: UInt8) -> String {
        switch type {
        case 32: return "VPS"
        case 33: return "SPS"
        case 34: return "PPS"
        default: return "NAL type \(type)"
        }
    }

    private enum BoxType {
        static let track = try! FourCharCode("trak")
        static let trackHeader = try! FourCharCode("tkhd")
        static let sampleDescription = try! FourCharCode("stsd")
    }
}

private final class FragmentSequenceRule: BoxValidationRule, @unchecked Sendable {
    private var lastSequenceNumber: UInt32?
    private var lastHeader: BoxHeader?

    func issues(for event: ParseEvent, reader _: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }
        guard header.type == BoxType.movieFragmentHeader else { return [] }
        guard let fragment = event.payload?.movieFragmentHeader else { return [] }

        var issues: [ValidationIssue] = []

        if fragment.sequenceNumber == 0 {
            let message = "\(header.identifierString) sequence number is zero; fragments should start at 1."
            issues.append(ValidationIssue(ruleID: "VR-016", message: message, severity: .warning))
        }

        if let previous = lastSequenceNumber, fragment.sequenceNumber <= previous {
            let previousLabel = lastHeader?.identifierString ?? "previous fragment"
            let message = "\(header.identifierString) has non-monotonic sequence number \(fragment.sequenceNumber) (previous \(previousLabel) used \(previous))."
            issues.append(ValidationIssue(ruleID: "VR-016", message: message, severity: .warning))
        }

        lastSequenceNumber = fragment.sequenceNumber
        lastHeader = header
        return issues
    }

    private enum BoxType {
        static let movieFragmentHeader = try! FourCharCode("mfhd")
    }
}

private struct FragmentRunValidationRule: BoxValidationRule {
    func issues(for event: ParseEvent, reader _: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }
        guard header.type == BoxType.trackRun else { return [] }
        guard let run = event.payload?.trackRun else { return [] }

        var issues: [ValidationIssue] = []
        let context = contextDescription(for: run)

        if run.sampleCount == 0 {
            let message = "Track fragment run\(context) declares 0 samples; ensure track run entries are present."
            issues.append(ValidationIssue(ruleID: "VR-017", message: message, severity: .error))
        }

        let missingDurations = missingDurationEntryIndexes(in: run)
        if !missingDurations.isEmpty {
            let entriesLabel = missingDurations.map(String.init).joined(separator: ", ")
            let message = "Track fragment run\(context) is missing sample durations for entries [\(entriesLabel)]; cannot advance decode timeline."
            issues.append(ValidationIssue(ruleID: "VR-017", message: message, severity: .error))
        }

        return issues
    }

    private enum BoxType {
        static let trackRun = try! FourCharCode("trun")
    }

    private func contextDescription(for run: ParsedBoxPayload.TrackRunBox) -> String {
        var descriptors: [String] = []
        if let trackID = run.trackID {
            descriptors.append("track \(trackID)")
        }
        if let runIndex = run.runIndex {
            descriptors.append("run #\(runIndex)")
        }
        if let first = run.firstSampleGlobalIndex {
            if run.sampleCount > 0 {
                let count = UInt64(run.sampleCount)
                if count == 1 {
                    descriptors.append("sample \(first)")
                } else {
                    let (candidate, overflow) = first.addingReportingOverflow(count - 1)
                    if overflow {
                        descriptors.append("sample range starting at \(first)")
                    } else {
                        descriptors.append("samples \(first)-\(candidate)")
                    }
                }
            } else {
                descriptors.append("first sample \(first)")
            }
        }
        guard !descriptors.isEmpty else { return "" }
        return " for " + descriptors.joined(separator: ", ")
    }

    private func missingDurationEntryIndexes(in run: ParsedBoxPayload.TrackRunBox) -> [UInt32] {
        run.entries.compactMap { entry in
            guard entry.sampleDuration == nil else { return nil }
            return entry.index
        }
    }
}

private struct UnknownBoxRule: BoxValidationRule {
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }
        guard event.metadata == nil else { return [] }
        return [ValidationIssue(
            ruleID: "VR-006",
            message: "Unknown box type \(header.identifierString) encountered; schedule catalog research.",
            severity: .info
        )]
    }
}

private final class TopLevelOrderingAdvisoryRule: BoxValidationRule, @unchecked Sendable {
    private static let ruleID = "E3"
    private static let fileType = "ftyp"
    private static let movieType = FourCharContainerCode.moov.rawValue
    private static let paddingTypes: Set<String> = ["free", "skip", "wide"]
    private static let allowedPreFileTypeTypes: Set<String> = paddingTypes.union(["uuid"])
    private static let streamingIndicatorTypes: Set<String> = {
        var values = Set(MediaAndIndexBoxCode.streamingIndicators.map(\.rawValue))
        values.insert(FourCharContainerCode.moof.rawValue)
        return values
    }()
    private static let allowedBetweenTypes: Set<String> =
        allowedPreFileTypeTypes.union(streamingIndicatorTypes)

    private var hasSeenFileType = false
    private var hasSeenMovie = false
    private var typesBeforeFileType: [String] = []
    private var typesBetweenFileTypeAndMovie: [String] = []
    private var streamingIndicatorsBeforeMovie: Set<String> = []
    private var mediaPayloadTypesBeforeMovie: Set<String> = []
    private var emittedFileTypeAdvisory = false
    private var emittedMovieAdvisory = false

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, depth) = event.kind, depth == 0 else { return [] }
        let type = header.type.rawValue

        if hasSeenFileType, !hasSeenMovie, type != Self.movieType {
            if Self.streamingIndicatorTypes.contains(type) {
                streamingIndicatorsBeforeMovie.insert(type)
            }
            if MediaAndIndexBoxCode.isMediaPayload(type) {
                mediaPayloadTypesBeforeMovie.insert(type)
            }
        }

        if type == Self.fileType {
            if !hasSeenFileType {
                hasSeenFileType = true
                return fileTypeIssuesIfNeeded()
            }
            return []
        }

        if !hasSeenFileType {
            typesBeforeFileType.append(type)
            return []
        }

        if hasSeenMovie {
            return []
        }

        if type == Self.movieType {
            hasSeenMovie = true
            return movieIssuesIfNeeded()
        }

        typesBetweenFileTypeAndMovie.append(type)
        return []
    }

    private func fileTypeIssuesIfNeeded() -> [ValidationIssue] {
        guard !emittedFileTypeAdvisory else { return [] }
        let unexpected = Set(typesBeforeFileType.filter { !Self.allowedPreFileTypeTypes.contains($0) })
        guard !unexpected.isEmpty else { return [] }
        emittedFileTypeAdvisory = true
        let summary = Self.describe(unexpected)
        let message = "Top-level box \(summary) appeared before the file type box (ftyp); verify muxer packaging order."
        return [ValidationIssue(ruleID: Self.ruleID, message: message, severity: .warning)]
    }

    private func movieIssuesIfNeeded() -> [ValidationIssue] {
        guard !emittedMovieAdvisory else { return [] }

        let unexpected = Set(typesBetweenFileTypeAndMovie.filter { type in
            !Self.allowedBetweenTypes.contains(type) && !MediaAndIndexBoxCode.isMediaPayload(type)
        })
        if !unexpected.isEmpty {
            emittedMovieAdvisory = true
            let summary = Self.describe(unexpected)
            let message = "Top-level box \(summary) appeared between file type (ftyp) and movie (moov) boxes; review packaging workflow."
            return [ValidationIssue(ruleID: Self.ruleID, message: message, severity: .warning)]
        }

        if !mediaPayloadTypesBeforeMovie.isEmpty, !streamingIndicatorsBeforeMovie.isEmpty {
            emittedMovieAdvisory = true
            let mediaSummary = Self.describe(mediaPayloadTypesBeforeMovie)
            let indicatorSummary = Self.describe(streamingIndicatorsBeforeMovie)
            let message = "Movie box (moov) arrived after media payload \(mediaSummary) following streaming indicators \(indicatorSummary); confirm initialization metadata remains accessible."
            return [ValidationIssue(ruleID: Self.ruleID, message: message, severity: .warning)]
        }

        return []
    }

    private static func describe(_ codes: Set<String>) -> String {
        describe(Array(codes))
    }

    private static func describe(_ codes: [String]) -> String {
        let unique = Array(Set(codes)).sorted()
        guard let first = unique.first else { return "" }
        if unique.count == 1 {
            return "\"\(first)\""
        }
        if unique.count == 2 {
            return "\"\(first)\" and \"\(unique[1])\""
        }
        return "\"\(first)\" and \(unique.count - 1) others"
    }
}

private final class FileTypeOrderingRule: BoxValidationRule, @unchecked Sendable {
    private var hasSeenFileType = false

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }

        let type = header.type.rawValue
        if type == "ftyp" {
            hasSeenFileType = true
            return []
        }

        guard !hasSeenFileType, Self.mediaBoxTypes.contains(type) else {
            return []
        }

        let message = "Encountered \(header.identifierString) before required file type box (ftyp)."
        return [ValidationIssue(ruleID: "VR-004", message: message, severity: .error)]
    }

    private static let mediaBoxTypes: Set<String> = {
        var values: Set<String> = [
            FourCharContainerCode.moov.rawValue,
            FourCharContainerCode.trak.rawValue,
            FourCharContainerCode.mdia.rawValue,
            FourCharContainerCode.minf.rawValue,
            FourCharContainerCode.stbl.rawValue,
            FourCharContainerCode.moof.rawValue,
            FourCharContainerCode.traf.rawValue,
            FourCharContainerCode.mvex.rawValue
        ]
        values.formUnion(MediaAndIndexBoxCode.rawValueSet)
        return values
    }()
}

private final class MovieDataOrderingRule: BoxValidationRule, @unchecked Sendable {
    private var hasSeenMovieBox = false
    private var hasStreamingIndicator = false

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }

        let type = header.type.rawValue

        if Self.streamingIndicatorTypes.contains(type) {
            hasStreamingIndicator = true
        }

        if type == FourCharContainerCode.moov.rawValue {
            hasSeenMovieBox = true
            return []
        }

        guard MediaAndIndexBoxCode.isMediaPayload(type) else { return [] }
        guard !hasSeenMovieBox, !hasStreamingIndicator else { return [] }

        let message = "Movie data box (mdat) encountered before movie box (moov); ensure initialization metadata precedes media."
        return [ValidationIssue(ruleID: "VR-005", message: message, severity: .warning)]
    }

    private static let streamingIndicatorTypes: Set<String> = {
        var values: Set<String> = [
            FourCharContainerCode.moof.rawValue,
            FourCharContainerCode.mvex.rawValue,
            "ssix",
            "prft"
        ]
        values.formUnion(MediaAndIndexBoxCode.streamingIndicators.map(\.rawValue))
        return values
    }()
}

private extension Range where Bound == Int64 {
    var count: Int { Int(upperBound - lowerBound) }
}

private extension UInt32 {
    func paddedHex(length: Int) -> String {
        let value = String(self, radix: 16, uppercase: true)
        guard value.count < length else { return value }
        return String(repeating: "0", count: length - value.count) + value
    }
}
