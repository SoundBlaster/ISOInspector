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
            VersionFlagsRule(),
            EditListValidationRule(),
            SampleTableCorrelationRule(),
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
    /// Context for tracking sample tables within a single track
    private struct TrackContext {
        var sampleToChunk: ParsedBoxPayload.SampleToChunkBox?
        var sampleSize: ParsedBoxPayload.SampleSizeBox?
        var compactSampleSize: ParsedBoxPayload.CompactSampleSizeBox?
        var chunkOffset: ParsedBoxPayload.ChunkOffsetBox?
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
            case BoxType.sampleToChunk:
                if let detail = event.payload?.sampleToChunk {
                    trackStack[trackIndex].sampleToChunk = detail
                }
                return []
            case BoxType.sampleSize:
                if let detail = event.payload?.sampleSize {
                    trackStack[trackIndex].sampleSize = detail
                }
                return []
            case BoxType.compactSampleSize:
                if let detail = event.payload?.compactSampleSize {
                    trackStack[trackIndex].compactSampleSize = detail
                }
                return []
            case BoxType.chunkOffset, BoxType.chunkOffset64:
                if let detail = event.payload?.chunkOffset {
                    trackStack[trackIndex].chunkOffset = detail
                    // Validate correlation when chunk offset table arrives
                    return validateCorrelation(context: trackStack[trackIndex])
                }
                return []
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

    private func validateCorrelation(context: TrackContext) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        // VR-015: Chunk count correlation
        if let stsc = context.sampleToChunk, let stco = context.chunkOffset {
            let expectedChunkCount = computeExpectedChunkCount(from: stsc)
            let actualChunkCount = stco.entryCount

            if expectedChunkCount != actualChunkCount {
                issues.append(ValidationIssue(
                    ruleID: "VR-015",
                    message: "Sample table chunk count mismatch: stsc references \(expectedChunkCount) chunks, but stco/co64 declares \(actualChunkCount) chunks.",
                    severity: .warning
                ))
            }
        }

        // VR-015: Sample count correlation
        if let stsc = context.sampleToChunk, let stco = context.chunkOffset {
            let computedSampleCount = computeTotalSampleCount(from: stsc, chunkCount: stco.entryCount)

            if let stsz = context.sampleSize {
                if computedSampleCount != stsz.sampleCount {
                    issues.append(ValidationIssue(
                        ruleID: "VR-015",
                        message: "Sample table sample count mismatch: stsc computes \(computedSampleCount) samples across \(stco.entryCount) chunks, but stsz declares \(stsz.sampleCount) samples.",
                        severity: .warning
                    ))
                }
            } else if let stz2 = context.compactSampleSize {
                if computedSampleCount != stz2.sampleCount {
                    issues.append(ValidationIssue(
                        ruleID: "VR-015",
                        message: "Sample table sample count mismatch: stsc computes \(computedSampleCount) samples across \(stco.entryCount) chunks, but stz2 declares \(stz2.sampleCount) samples.",
                        severity: .warning
                    ))
                }
            }
        }

        // VR-015: Chunk offset monotonicity
        if let stco = context.chunkOffset {
            if let monotonicityIssue = validateChunkOffsetMonotonicity(stco) {
                issues.append(monotonicityIssue)
            }
        }

        return issues
    }

    /// Computes the total number of chunks referenced by stsc entries
    private func computeExpectedChunkCount(from stsc: ParsedBoxPayload.SampleToChunkBox) -> UInt32 {
        guard !stsc.entries.isEmpty else { return 0 }

        // The last entry's firstChunk tells us the last chunk index referenced.
        // Since chunks are 1-indexed in ISO spec, the count equals the last firstChunk value
        // plus any additional chunks implied by the last run.
        // However, stsc doesn't explicitly say how many chunks are in the last run.
        // The chunk count is determined by stco/co64.
        // So we use the maximum firstChunk value as the minimum expected chunk count.
        let maxFirstChunk = stsc.entries.map(\.firstChunk).max() ?? 0
        return maxFirstChunk
    }

    /// Computes the total number of samples by applying stsc runs across the given chunk count
    private func computeTotalSampleCount(
        from stsc: ParsedBoxPayload.SampleToChunkBox,
        chunkCount: UInt32
    ) -> UInt32 {
        guard !stsc.entries.isEmpty, chunkCount > 0 else { return 0 }

        var totalSamples: UInt32 = 0

        for (index, entry) in stsc.entries.enumerated() {
            let runStartChunk = entry.firstChunk
            let runEndChunk: UInt32

            if index + 1 < stsc.entries.count {
                // Not the last entry: run ends at (next entry's firstChunk - 1)
                runEndChunk = stsc.entries[index + 1].firstChunk - 1
            } else {
                // Last entry: run extends to the end of the chunk table
                runEndChunk = chunkCount
            }

            // Validate chunk range
            guard runStartChunk >= 1, runStartChunk <= chunkCount else { continue }
            guard runEndChunk >= runStartChunk, runEndChunk <= chunkCount else { continue }

            let chunksInRun = runEndChunk - runStartChunk + 1
            totalSamples += chunksInRun * entry.samplesPerChunk
        }

        return totalSamples
    }

    /// Validates that chunk offsets are monotonically increasing
    private func validateChunkOffsetMonotonicity(
        _ chunkOffset: ParsedBoxPayload.ChunkOffsetBox
    ) -> ValidationIssue? {
        guard chunkOffset.entries.count > 1 else { return nil }

        for i in 1..<chunkOffset.entries.count {
            let previousOffset = chunkOffset.entries[i - 1].offset
            let currentOffset = chunkOffset.entries[i].offset

            if currentOffset <= previousOffset {
                return ValidationIssue(
                    ruleID: "VR-015",
                    message: "Chunk offset table contains non-monotonic offsets: chunk \(i - 1) at offset \(previousOffset), chunk \(i) at offset \(currentOffset) (expected strictly increasing).",
                    severity: .warning
                )
            }
        }

        return nil
    }

    private enum BoxType {
        static let track = try! FourCharCode("trak")
        static let sampleToChunk = try! FourCharCode("stsc")
        static let sampleSize = try! FourCharCode("stsz")
        static let compactSampleSize = try! FourCharCode("stz2")
        static let chunkOffset = try! FourCharCode("stco")
        static let chunkOffset64 = try! FourCharCode("co64")
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
