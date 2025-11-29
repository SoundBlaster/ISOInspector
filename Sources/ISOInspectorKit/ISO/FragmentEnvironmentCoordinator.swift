import Foundation

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
}

extension FragmentEnvironmentCoordinator {
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
                  let detail = payload?.trackFragmentHeader
            else { return }
            var context = fragmentStack[index]
            context.header = detail
            context.trackID = detail.trackID
            let defaults = trackDefaults[detail.trackID]
            context.trackExtendsDefaults = defaults
            let descriptionIndex =
            detail.sampleDescriptionIndex
            ?? defaults?.defaultSampleDescriptionIndex
            ?? context.sampleDescriptionIndex
            ?? 1
            context.sampleDescriptionIndex = descriptionIndex
            context.defaultSampleDuration =
            detail.defaultSampleDuration ?? defaults?.defaultSampleDuration
            context.defaultSampleSize = detail.defaultSampleSize ?? defaults?.defaultSampleSize
            context.defaultSampleFlags = detail.defaultSampleFlags ?? defaults?.defaultSampleFlags
            if let base = detail.baseDataOffset {
                context.baseDataOffset = base
                context.dataCursor = base
            } else if context.baseDataOffset == nil, detail.defaultBaseIsMoof,
                      let moofStart = context.moofStart
            {
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
                  let detail = payload?.trackFragmentDecodeTime
            else { return }
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
                  let run = payload?.trackRun
            else { return }
            var context = fragmentStack[index]
            context.runs.append(run)
            let (newCount, overflowCount) = context.totalSampleCount.addingReportingOverflow(
                UInt64(run.sampleCount))
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
                    let (combined, overflow) = context.totalSampleDuration!.addingReportingOverflow(
                        runTotalDuration)
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

    func didFinishBox(header: BoxHeader) -> ParsedBoxPayload? {
        switch header.type {
        case BoxType.trackFragment:
            guard let context = fragmentStack.popLast() else { return nil }
            let defaults =
            context.trackExtendsDefaults
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
}

extension FragmentEnvironmentCoordinator {
    func environment(for header: BoxHeader) -> BoxParserRegistry.FragmentEnvironment {
        guard header.type == BoxType.trackRun,
              let index = fragmentStack.indices.last
        else {
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
           let moofStart = context.moofStart
        {
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
            baseDecodeTimeIs64Bit: context.decodeTime?.baseMediaDecodeTimeIs64Bit
            ?? context.baseDecodeTimeIs64Bit,
            trackExtendsDefaults: context.trackExtendsDefaults ?? defaults,
            trackFragmentHeader: context.header,
            trackFragmentDecodeTime: context.decodeTime,
            runIndex: context.runIndex,
            nextSampleNumber: context.nextSampleNumber
        )

        fragmentStack[index] = context
        return environment
    }
}

extension FragmentEnvironmentCoordinator {
    private func int64(from value: UInt64?) -> Int64? {
        guard let value, value <= UInt64(Int64.max) else { return nil }
        return Int64(value)
    }
}

extension FragmentEnvironmentCoordinator {
    private enum BoxType {
        static let movieFragment = try! FourCharCode("moof")
        static let trackFragment = try! FourCharCode("traf")
        static let trackFragmentHeader = try! FourCharCode("tfhd")
        static let trackFragmentDecodeTime = try! FourCharCode("tfdt")
        static let trackRun = try! FourCharCode("trun")
        static let trackExtends = try! FourCharCode("trex")
    }
}
