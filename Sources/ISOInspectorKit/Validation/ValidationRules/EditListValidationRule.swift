import Foundation

/// Validates edit lists and their correlation with movie, track, and media timing.
///
/// Edit lists (elst) define timeline mappings between movie time, track time, and media time.
/// This rule validates:
/// - Edit list duration matches movie header duration
/// - Edit list duration matches track header duration (for enabled tracks)
/// - Media consumption matches media header duration
/// - Playback rate restrictions (no reverse, no fractional, ≤ 1x)
///
/// ## Rule ID
/// - **VR-014**: Edit list validation
///
/// ## Severity
/// - **Warning**: Duration mismatches or unsupported playback rates
///
/// ## Example Violations
/// - Edit list spans 5000 movie ticks but movie header declares 5100 ticks
/// - Edit list consumes 3000 media ticks but media header declares 2900 ticks
/// - Edit list entry uses negative media_rate (reverse playback)
/// - Edit list entry uses fractional playback rates
final class EditListValidationRule: BoxValidationRule, @unchecked Sendable {  // swiftlint:disable:this type_body_length
    private struct MediaHeader {
        let timescale: UInt32
        let duration: UInt64
    }

    private struct PendingMediaCheck { let editList: ParsedBoxPayload.EditListBox }

    private struct TrackContext {
        var trackHeader: ParsedBoxPayload.TrackHeaderBox?
        var mediaHeader: MediaHeader?
        var pendingMediaChecks: [PendingMediaCheck] = []
    }

    private var movieTimescale: UInt32?
    private var movieDuration: UInt64?
    private var trackStack: [TrackContext] = []

    // swiftlint:disable:next cyclomatic_complexity
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        switch event.kind {
        case .willStartBox(let header, let depth):
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
            case BoxType.mediaHeader: return handleMediaHeader(event: event, trackIndex: trackIndex)
            case BoxType.editList: return handleEditList(event: event, trackIndex: trackIndex)
            default: return []
            }
        case .didFinishBox(let header, let depth):
            trimStack(to: depth)
            if header.type == BoxType.track, !trackStack.isEmpty { trackStack.removeLast() }
            return []
        }
    }

    private func trimStack(to depth: Int) {
        if trackStack.count > depth { trackStack.removeLast(trackStack.count - depth) }
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
                    for: pending.editList, mediaHeader: mediaHeader,
                    trackContext: trackStack[trackIndex])
                {
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
                for: editList, mediaHeader: mediaHeader, trackContext: context)
            {
                issues.append(issue)
            }
        } else {
            trackStack[trackIndex].pendingMediaChecks.append(PendingMediaCheck(editList: editList))
        }

        issues.append(contentsOf: rateIssues(for: editList, trackContext: context))

        return issues
    }

    private func movieDurationIssue(
        for editList: ParsedBoxPayload.EditListBox, trackContext: TrackContext
    ) -> ValidationIssue? {
        guard let movieTimescale = editList.movieTimescale ?? movieTimescale, movieTimescale > 0,
            let movieDuration = movieDuration
        else { return nil }

        let total = editList.entries.reduce(UInt64(0)) { $0 &+ $1.segmentDuration }
        let tolerance = UInt64(1)

        if total + tolerance < movieDuration {
            let diff = movieDuration - total
            return ValidationIssue(
                ruleID: "VR-014",
                message:
                    "\(trackDescription(for: trackContext)) edit list spans \(total) movie ticks but movie header duration is \(movieDuration) (short by \(diff) > 1 tick).",
                severity: .warning)
        } else if total > movieDuration + tolerance {
            let diff = total - movieDuration
            return ValidationIssue(
                ruleID: "VR-014",
                message:
                    "\(trackDescription(for: trackContext)) edit list spans \(total) movie ticks but movie header duration is \(movieDuration) (over by \(diff) > 1 tick).",
                severity: .warning)
        }

        return nil
    }

    private func trackDurationIssue(
        for editList: ParsedBoxPayload.EditListBox, trackContext: TrackContext
    ) -> ValidationIssue? {
        guard let trackHeader = trackContext.trackHeader, trackHeader.isEnabled else { return nil }
        let total = editList.entries.reduce(UInt64(0)) { $0 &+ $1.segmentDuration }
        let tolerance = UInt64(1)
        let declared = trackHeader.duration

        if total + tolerance < declared {
            let diff = declared - total
            return ValidationIssue(
                ruleID: "VR-014",
                message:
                    "\(trackDescription(for: trackContext, trackHeader: trackHeader)) edit list spans \(total) movie ticks but track header duration is \(declared) (short by \(diff) > 1 tick).",
                severity: .warning)
        } else if total > declared + tolerance {
            let diff = total - declared
            return ValidationIssue(
                ruleID: "VR-014",
                message:
                    "\(trackDescription(for: trackContext, trackHeader: trackHeader)) edit list spans \(total) movie ticks but track header duration is \(declared) (over by \(diff) > 1 tick).",
                severity: .warning)
        }

        return nil
    }

    // swiftlint:disable:next function_body_length
    private func mediaDurationIssue(
        for editList: ParsedBoxPayload.EditListBox, mediaHeader: MediaHeader,
        trackContext: TrackContext
    ) -> ValidationIssue? {
        guard let movieTimescale = editList.movieTimescale ?? movieTimescale, movieTimescale > 0,
            mediaHeader.timescale > 0
        else { return nil }

        if let trackHeader = trackContext.trackHeader, !trackHeader.isEnabled { return nil }

        guard
            let expected = expectedMediaDuration(
                for: editList, movieTimescale: movieTimescale, mediaTimescale: mediaHeader.timescale
            )
        else { return nil }

        let tolerance = UInt64(1)
        if expected + tolerance < mediaHeader.duration {
            let diff = mediaHeader.duration - expected
            return ValidationIssue(
                ruleID: "VR-014",
                message:
                    "\(trackDescription(for: trackContext)) edit list consumes \(expected) media ticks but media duration is \(mediaHeader.duration) (short by \(diff) > 1 tick).",
                severity: .warning)
        } else if expected > mediaHeader.duration + tolerance {
            let diff = expected - mediaHeader.duration
            return ValidationIssue(
                ruleID: "VR-014",
                message:
                    "\(trackDescription(for: trackContext)) edit list consumes \(expected) media ticks but media duration is \(mediaHeader.duration) (over by \(diff) > 1 tick).",
                severity: .warning)
        }

        return nil
    }

    private func rateIssues(for editList: ParsedBoxPayload.EditListBox, trackContext: TrackContext)
        -> [ValidationIssue]
    {
        editList.entries.enumerated().compactMap { index, entry in
            if entry.mediaRateFraction != 0 {
                return ValidationIssue(
                    ruleID: "VR-014",
                    message:
                        "\(trackDescription(for: trackContext)) edit list entry \(index) sets media_rate_fraction=\(entry.mediaRateFraction); fractional playback rates are unsupported.",
                    severity: .warning)
            }

            if entry.mediaRateInteger < 0 {
                return ValidationIssue(
                    ruleID: "VR-014",
                    message:
                        "\(trackDescription(for: trackContext)) edit list entry \(index) uses media_rate_integer=\(entry.mediaRateInteger); reverse playback is unsupported.",
                    severity: .warning)
            }

            if entry.mediaRateInteger > 1 {
                return ValidationIssue(
                    ruleID: "VR-014",
                    message:
                        "\(trackDescription(for: trackContext)) edit list entry \(index) uses media_rate_integer=\(entry.mediaRateInteger); playback rate adjustments above 1x are unsupported.",
                    severity: .warning)
            }

            return nil
        }
    }

    private func expectedMediaDuration(
        for editList: ParsedBoxPayload.EditListBox, movieTimescale: UInt32, mediaTimescale: UInt32
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
            let duration = UInt64(durationValue)
        else { return nil }

        return MediaHeader(timescale: timescale, duration: duration)
    }

    private func trackDescription(
        for context: TrackContext, trackHeader: ParsedBoxPayload.TrackHeaderBox? = nil
    ) -> String {
        let header = trackHeader ?? context.trackHeader
        if let trackID = header?.trackID { return "Track \(trackID)" }
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
