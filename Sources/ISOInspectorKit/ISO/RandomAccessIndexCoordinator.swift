import Foundation

final class RandomAccessIndexCoordinator: @unchecked Sendable {
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
    private var fragmentsByOffset: [UInt64: BoxParserRegistry.RandomAccessEnvironment.Fragment] =
        [:]
    private var mfraStack: [MfraContext] = []

    func willStartBox(header: BoxHeader) {
        switch header.type {
        case BoxType.movieFragment:
            let start = header.startOffset >= 0 ? UInt64(header.startOffset) : 0
            moofStack.append(MoofContext(startOffset: start))
        case BoxType.movieFragmentRandomAccess: mfraStack.append(MfraContext())
        default: break
        }
    }

    func didParsePayload(header: BoxHeader, payload: ParsedBoxPayload?) {
        switch header.type {
        case BoxType.movieFragmentHeader:
            if let index = moofStack.indices.last,
                let sequence = payload?.movieFragmentHeader?.sequenceNumber
            {
                moofStack[index].sequenceNumber = sequence
            }
        case BoxType.trackFragmentRandomAccess:
            if let index = mfraStack.indices.last, let table = payload?.trackFragmentRandomAccess {
                mfraStack[index].trackTables.append(table)
            }
        case BoxType.movieFragmentRandomAccessOffset:
            if let index = mfraStack.indices.last,
                let offset = payload?.movieFragmentRandomAccessOffset
            {
                mfraStack[index].offset = offset
            }
        default: break
        }
    }

    func didFinishBox(header: BoxHeader, payload: ParsedBoxPayload?) -> ParsedBoxPayload? {
        switch header.type {
        case BoxType.trackFragment:
            guard let index = moofStack.indices.last, let summary = payload?.trackFragment else {
                return nil
            }
            var context = moofStack[index]
            context.trackFragments.append(
                TrackFragmentRecord(order: context.nextOrder, detail: summary))
            context.nextOrder &+= 1
            moofStack[index] = context
            return nil
        case BoxType.movieFragment:
            guard let context = moofStack.popLast() else { return nil }
            let trackFragments = context.trackFragments.map { record in
                BoxParserRegistry.RandomAccessEnvironment.TrackFragment(
                    order: record.order, detail: record.detail)
            }
            let fragment = BoxParserRegistry.RandomAccessEnvironment.Fragment(
                sequenceNumber: context.sequenceNumber, trackFragments: trackFragments)
            fragmentsByOffset[context.startOffset] = fragment
            return nil
        case BoxType.movieFragmentRandomAccess:
            guard let context = mfraStack.popLast() else { return nil }
            let summaries: [ParsedBoxPayload.MovieFragmentRandomAccessBox.TrackSummary] = context
                .trackTables.map { table in
                    let times = table.entries.map { $0.time }
                    let earliest = times.min()
                    let latest = times.max()
                    let fragments = Array(
                        Set(table.entries.compactMap { $0.fragmentSequenceNumber })
                    ).sorted()
                    return ParsedBoxPayload.MovieFragmentRandomAccessBox.TrackSummary(
                        trackID: table.trackID, entryCount: table.entries.count,
                        earliestTime: earliest, latestTime: latest,
                        referencedFragmentSequenceNumbers: fragments)
                }
            let total = context.trackTables.reduce(0) { $0 + $1.entries.count }
            let detail = ParsedBoxPayload.MovieFragmentRandomAccessBox(
                tracks: summaries, totalEntryCount: total, offset: context.offset)
            return ParsedBoxPayload(detail: .movieFragmentRandomAccess(detail))
        default: return nil
        }
    }

    func environment(for header: BoxHeader) -> BoxParserRegistry.RandomAccessEnvironment {
        var mapping = fragmentsByOffset
        for context in moofStack {
            if mapping[context.startOffset] != nil { continue }
            let fragments = context.trackFragments.map { record in
                BoxParserRegistry.RandomAccessEnvironment.TrackFragment(
                    order: record.order, detail: record.detail)
            }
            mapping[context.startOffset] = BoxParserRegistry.RandomAccessEnvironment.Fragment(
                sequenceNumber: context.sequenceNumber, trackFragments: fragments)
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
