import Foundation
import XCTest
@testable import ISOInspectorKit

final class ParsePipelineLiveTests: XCTestCase {
    func testLivePipelineEmitsEventsForNestedBoxes() async throws {
        let tkhd = makeBox(type: "tkhd", payload: Data())
        let trak = makeBox(type: ContainerTypes.track, payload: tkhd)
        let moov = makeBox(type: ContainerTypes.movie, payload: trak)
        let ftypPayload = Data(repeating: 0, count: 16)
        let ftyp = makeBox(type: "ftyp", payload: ftypPayload)
        let data = ftyp + moov

        let reader = InMemoryRandomAccessReader(data: data)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        XCTAssertEqual(events.count, 8)
        try assertEvent(events[0], kind: .willStart, type: "ftyp", depth: 0, offset: 0)
        try assertEvent(events[1], kind: .didFinish, type: "ftyp", depth: 0, offset: Int64(ftyp.count))
        try assertEvent(events[2], kind: .willStart, type: ContainerTypes.movie, depth: 0, offset: Int64(ftyp.count))
        try assertEvent(events[3], kind: .willStart, type: ContainerTypes.track, depth: 1, offset: Int64(ftyp.count + 8))
        try assertEvent(events[4], kind: .willStart, type: "tkhd", depth: 2, offset: Int64(ftyp.count + 16))
        try assertEvent(events[5], kind: .didFinish, type: "tkhd", depth: 2, offset: Int64(ftyp.count + moov.count))
        try assertEvent(events[6], kind: .didFinish, type: ContainerTypes.track, depth: 1, offset: Int64(ftyp.count + moov.count))
        try assertEvent(events[7], kind: .didFinish, type: ContainerTypes.movie, depth: 0, offset: Int64(ftyp.count + moov.count))
    }

    func testRandomAccessTableCorrelatesWithFragments() async throws {
        let sequenceNumber: UInt32 = 7
        let trackID: UInt32 = 1
        let baseDecodeTime: UInt64 = 9_000
        let sampleDurations: [UInt32] = [3_000, 3_000, 3_000]
        let sampleSizes: [UInt32] = [1_200, 1_500, 1_800]
        let dataOffset: Int32 = 64
        let baseDataOffset: UInt64 = 4_096

        let mfhd = makeMovieFragmentHeaderBox(sequenceNumber: sequenceNumber)
        let tfhd = makeTrackFragmentHeaderBox(
            trackID: trackID,
            baseDataOffset: baseDataOffset,
            defaultSampleDuration: sampleDurations[0],
            defaultSampleSize: sampleSizes[0],
            defaultSampleFlags: 0
        )
        let tfdt = makeTrackFragmentDecodeTimeBox(baseDecodeTime: baseDecodeTime)
        let trun = makeTrackRunBox(
            sampleCount: UInt32(sampleDurations.count),
            dataOffset: dataOffset,
            sampleDurations: sampleDurations,
            sampleSizes: sampleSizes
        )
        let traf = makeContainer(type: ContainerTypes.trackFragment, children: [tfhd, tfdt, trun])
        let moof = makeContainer(type: ContainerTypes.movieFragment, children: [mfhd, traf])

        let tfra = makeTrackFragmentRandomAccessBox(
            version: 1,
            trackID: trackID,
            entries: [
                .init(
                    time: baseDecodeTime + UInt64(sampleDurations[0]),
                    moofOffset: 0,
                    trafNumber: 1,
                    trunNumber: 1,
                    sampleNumber: 2
                )
            ]
        )
        let mfra = makeMovieFragmentRandomAccessBox(trackEntries: [tfra])

        let data = moof + mfra
        let reader = InMemoryRandomAccessReader(data: data)
        let pipeline = ParsePipeline.live()
        let events = try await collectEvents(from: pipeline.events(for: reader))

        let tfraEvent = try XCTUnwrap(events.first { event in
            guard case let .willStartBox(header, _) = event.kind else { return false }
            return header.type.rawValue == "tfra"
        })
        let tfraDetail = try XCTUnwrap(tfraEvent.payload?.trackFragmentRandomAccess)
        XCTAssertEqual(tfraDetail.trackID, trackID)
        XCTAssertEqual(tfraDetail.entries.count, 1)

        let entry = try XCTUnwrap(tfraDetail.entries.first)
        XCTAssertEqual(entry.fragmentSequenceNumber, sequenceNumber)
        XCTAssertEqual(entry.trafNumber, 1)
        XCTAssertEqual(entry.trunNumber, 1)
        XCTAssertEqual(entry.sampleNumber, 2)
        XCTAssertEqual(entry.resolvedDecodeTime, baseDecodeTime + UInt64(sampleDurations[0]))
        XCTAssertEqual(entry.resolvedPresentationTime, Int64(baseDecodeTime + UInt64(sampleDurations[0])))
        XCTAssertEqual(entry.resolvedDataOffset, baseDataOffset + UInt64(Int64(dataOffset)) + UInt64(sampleSizes[0]))
        XCTAssertEqual(entry.resolvedSampleSize, sampleSizes[1])

        let mfraEvent = try XCTUnwrap(events.first { event in
            guard case let .didFinishBox(header, _) = event.kind else { return false }
            return header.type.rawValue == "mfra"
        })
        let mfraDetail = try XCTUnwrap(mfraEvent.payload?.movieFragmentRandomAccess)
        XCTAssertEqual(mfraDetail.totalEntryCount, 1)
        XCTAssertEqual(mfraDetail.tracks.count, 1)
        XCTAssertEqual(mfraDetail.tracks.first?.trackID, trackID)
        XCTAssertEqual(mfraDetail.tracks.first?.entryCount, 1)
        XCTAssertEqual(mfraDetail.tracks.first?.referencedFragmentSequenceNumbers, [sequenceNumber])
        XCTAssertEqual(mfraDetail.offset?.mfraSize, UInt32(mfra.count))
    }

    func testLivePipelineHandlesLargeSizeBoxes() async throws {
        let payload = Data(repeating: 0xFF, count: 12)
        let mediaType = MediaAndIndexBoxCode.mediaData.rawValue
        let largeBox = makeBox(type: mediaType, payload: payload, useLargeSize: true)
        let data = largeBox
        let reader = InMemoryRandomAccessReader(data: data)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        XCTAssertEqual(events.count, 2)
        try assertEvent(events[0], kind: .willStart, type: mediaType, depth: 0, offset: 0)
        try assertEvent(events[1], kind: .didFinish, type: mediaType, depth: 0, offset: Int64(largeBox.count))
    }

    func testLivePipelineRecordsMediaDataOffsetsWithoutReadingPayload() async throws {
        let payloadLength = 256
        let mediaType = MediaAndIndexBoxCode.mediaData.rawValue
        let mdat = makeBox(type: mediaType, payload: Data(count: payloadLength))
        let payloadRange: Range<Int64> = 8..<Int64(mdat.count)
        let reader = PayloadSpyRandomAccessReader(data: mdat, payloadRange: payloadRange)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let mdatEvent = try XCTUnwrap(events.first { event in
            guard case let .willStartBox(header, _) = event.kind else { return false }
            return header.type.rawValue == mediaType
        })

        let detail = try XCTUnwrap(mdatEvent.payload?.mediaData)
        XCTAssertEqual(detail.headerStartOffset, 0)
        XCTAssertEqual(detail.totalSize, Int64(mdat.count))
        XCTAssertEqual(detail.payloadRange, payloadRange)
        XCTAssertEqual(detail.payloadLength, Int64(payloadLength))

        XCTAssertFalse(reader.didReadPayload)
    }

    func testLivePipelineEmitsPaddingDetailsForFreeAndSkip() async throws {
        let ftyp = makeBox(type: "ftyp", payload: Data(count: 16))
        let freePayload = Data(count: 12)
        let free = makeBox(type: "free", payload: freePayload)
        let skip = makeBox(type: "skip", payload: Data())
        let mdat = makeBox(type: MediaAndIndexBoxCode.mediaData.rawValue, payload: Data(count: 4))
        let data = ftyp + free + skip + mdat

        let reader = InMemoryRandomAccessReader(data: data)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        var sawFree = false
        var sawSkip = false

        for event in events {
            guard case let .willStartBox(header, _) = event.kind else { continue }
            guard let payload = event.payload else { continue }
            switch header.type.rawValue {
            case "free":
                sawFree = true
                let padding = try XCTUnwrap(payload.padding)
                XCTAssertEqual(padding.type.rawValue, "free")
                XCTAssertEqual(padding.headerStartOffset, header.startOffset)
                XCTAssertEqual(padding.headerEndOffset, header.startOffset + header.headerSize)
                XCTAssertEqual(padding.totalSize, header.totalSize)
                XCTAssertEqual(padding.payloadRange, header.payloadRange)
                XCTAssertEqual(padding.payloadLength, Int64(freePayload.count))
                XCTAssertTrue(payload.fields.isEmpty)
            case "skip":
                sawSkip = true
                let padding = try XCTUnwrap(payload.padding)
                XCTAssertEqual(padding.type.rawValue, "skip")
                XCTAssertEqual(padding.headerStartOffset, header.startOffset)
                XCTAssertEqual(padding.headerEndOffset, header.startOffset + header.headerSize)
                XCTAssertEqual(padding.totalSize, header.totalSize)
                XCTAssertEqual(padding.payloadRange, header.payloadRange)
                XCTAssertEqual(padding.payloadLength, 0)
                XCTAssertTrue(payload.fields.isEmpty)
            default:
                continue
            }
        }

        XCTAssertTrue(sawFree)
        XCTAssertTrue(sawSkip)
    }

    func testLivePipelinePropagatesHeaderErrors() async {
        var corrupted = Data()
        corrupted.append(contentsOf: UInt32(24).bigEndianBytes)
        corrupted.append(contentsOf: "ftyp".utf8)
        corrupted.append(Data(repeating: 0, count: 4))
        // Missing remaining payload bytes triggers truncated read.
        let reader = InMemoryRandomAccessReader(data: corrupted)
        let pipeline = ParsePipeline.live()

        var iterator = pipeline.events(for: reader).makeAsyncIterator()
        do {
            _ = try await iterator.next()
            XCTFail("Expected stream to throw")
        } catch let error as BoxHeaderDecodingError {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLivePipelineAttachesMetadataForKnownBoxes() async throws {
        let known = makeBox(type: "ftyp", payload: Data(count: 20))
        let unknown = makeBox(type: "zzzz", payload: Data())
        let data = known + unknown

        let reader = InMemoryRandomAccessReader(data: data)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        let startEvents = events.compactMap { event -> ParseEvent? in
            if case .willStartBox = event.kind { return event }
            return nil
        }
        XCTAssertEqual(startEvents.count, 2)

        XCTAssertEqual(startEvents[0].metadata?.name, "File Type And Compatibility")
        XCTAssertNil(startEvents[1].metadata)
        XCTAssertTrue(startEvents[0].validationIssues.isEmpty)
        XCTAssertEqual(startEvents[1].validationIssues.count, 1)
        XCTAssertEqual(startEvents[1].validationIssues.first?.ruleID, "VR-006")
    }

    func testLivePipelineAttachesParsedPayloadFromRegistry() async throws {
        let payload = Data("isom".utf8) + Data([0x00, 0x00, 0x00, 0x00])
        let box = makeBox(type: "ftyp", payload: payload)
        let reader = InMemoryRandomAccessReader(data: box)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let ftypEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "ftyp"
            }
            return false
        }))

        let parsedPayload = try XCTUnwrap(ftypEvent.payload)
        XCTAssertEqual(parsedPayload.fields.first?.name, "major_brand")
        XCTAssertEqual(parsedPayload.fields.first?.value, "isom")
        let fileType = try XCTUnwrap(parsedPayload.fileType)
        XCTAssertEqual(fileType.majorBrand.rawValue, "isom")
        XCTAssertEqual(fileType.minorVersion, 0)
        XCTAssertEqual(fileType.compatibleBrands, [])
    }

    func testLivePipelineNormalizesEditListUsingHeaderTimescales() async throws {
        let mvhd = makeMovieHeaderBox(timescale: 600, duration: 1_800)
        let tkhd = makeTrackHeaderBox(trackID: 1, duration: 1_800, width: 0, height: 0)
        let mdhd = makeMediaHeaderBox(timescale: 48_000, duration: 96_000)
        let mdia = makeContainer(type: ContainerTypes.media, children: [mdhd])
        let elst = makeEditListBox(entries: [
            .init(segmentDuration: 600, mediaTime: 0, mediaRateInteger: 1, mediaRateFraction: 0)
        ])
        let edts = makeContainer(type: FourCharContainerCode.edts.rawValue, children: [elst])
        let trak = makeContainer(type: ContainerTypes.track, children: [tkhd, mdia, edts])
        let moov = makeContainer(type: ContainerTypes.movie, children: [mvhd, trak])

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let editListEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "elst"
            }
            return false
        })

        let payload = try XCTUnwrap(editListEvent.payload)
        XCTAssertEqual(field(named: "entries[0].segment_duration_seconds", in: payload), "1.000000")
        XCTAssertEqual(field(named: "entries[0].media_time_seconds", in: payload), "0.000000")
        XCTAssertEqual(field(named: "entries[0].presentation_end_seconds", in: payload), "1.000000")

        let detail = try XCTUnwrap(payload.editList)
        XCTAssertEqual(detail.movieTimescale, 600)
        XCTAssertEqual(detail.mediaTimescale, 48_000)
        let entry = try XCTUnwrap(detail.entries.first)
        XCTAssertEqual(try XCTUnwrap(entry.segmentDurationSeconds), 1.0, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(entry.mediaTimeSeconds), 0.0, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(entry.presentationEndSeconds), 1.0, accuracy: 0.000_001)
    }

    func testEditListValidationFlagsDurationMismatches() async throws {
        let mvhd = makeMovieHeaderBox(timescale: 600, duration: 1_200)
        let tkhd = makeTrackHeaderBox(trackID: 2, duration: 1_200, width: 0, height: 0)
        let mdhd = makeMediaHeaderBox(timescale: 48_000, duration: 24_000)
        let elst = makeEditListBox(entries: [
            .init(segmentDuration: 300, mediaTime: 0, mediaRateInteger: 1, mediaRateFraction: 0),
            .init(segmentDuration: 300, mediaTime: 300, mediaRateInteger: 1, mediaRateFraction: 0)
        ])
        let mdia = makeContainer(type: ContainerTypes.media, children: [mdhd])
        let edts = makeContainer(type: FourCharContainerCode.edts.rawValue, children: [elst])
        let trak = makeContainer(type: ContainerTypes.track, children: [tkhd, mdia, edts])
        let moov = makeContainer(type: ContainerTypes.movie, children: [mvhd, trak])

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let editListEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "elst"
            }
            return false
        })

        let issues = editListEvent.validationIssues.filter { $0.ruleID == "VR-014" }
        XCTAssertEqual(issues.count, 3)
        XCTAssertTrue(issues.contains(where: { $0.message.contains("movie header duration") }))
        XCTAssertTrue(issues.contains(where: { $0.message.contains("track header duration") }))
        XCTAssertTrue(issues.contains(where: { $0.message.contains("media duration") }))
    }

    func testEditListValidationDefersMediaDurationUntilMediaHeader() async throws {
        let mvhd = makeMovieHeaderBox(timescale: 600, duration: 900)
        let tkhd = makeTrackHeaderBox(trackID: 4, duration: 900, width: 0, height: 0)
        let mdhd = makeMediaHeaderBox(timescale: 48_000, duration: 96_000)
        let elst = makeEditListBox(entries: [
            .init(segmentDuration: 900, mediaTime: 0, mediaRateInteger: 1, mediaRateFraction: 0)
        ])
        let edts = makeContainer(type: FourCharContainerCode.edts.rawValue, children: [elst])
        let mdia = makeContainer(type: ContainerTypes.media, children: [mdhd])
        let trak = makeContainer(type: ContainerTypes.track, children: [tkhd, edts, mdia])
        let moov = makeContainer(type: ContainerTypes.movie, children: [mvhd, trak])

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let editListEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "elst"
            }
            return false
        })

        let editListIssues = editListEvent.validationIssues.filter { $0.ruleID == "VR-014" }
        XCTAssertTrue(editListIssues.isEmpty)

        let mediaHeaderEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "mdhd"
            }
            return false
        })
        let mediaIssues = mediaHeaderEvent.validationIssues.filter { $0.ruleID == "VR-014" }
        XCTAssertEqual(mediaIssues.count, 1)
        XCTAssertTrue(mediaIssues.contains(where: { $0.message.contains("media duration") }))
    }

    func testLivePipelineStreamsParseIssueMetadata() async throws {
        let containerType = FourCharContainerCode.moov.rawValue
        var truncatedChild = Data()
        truncatedChild.append(contentsOf: UInt32(32).bigEndianBytes)
        truncatedChild.append(contentsOf: containerType.utf8)
        truncatedChild.append(Data(repeating: 0, count: 4))
        let container = makeBox(type: containerType, payload: truncatedChild)

        let reader = InMemoryRandomAccessReader(data: container)
        let pipeline = ParsePipeline.live(options: .tolerant)

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let finishEvent = try XCTUnwrap(events.first { event in
            if case let .didFinishBox(header, _) = event.kind {
                return header.type.rawValue == containerType
            }
            return false
        })

        XCTAssertFalse(finishEvent.issues.isEmpty)
        let issue = try XCTUnwrap(finishEvent.issues.first { $0.code == "payload.truncated" })
        XCTAssertEqual(issue.severity, .error)
        let range = try XCTUnwrap(issue.byteRange)
        XCTAssertEqual(range.lowerBound, 8)
        XCTAssertEqual(range.upperBound, Int64(container.count))
    }

    func testEditListValidationFlagsUnsupportedRates() async throws {
        let mvhd = makeMovieHeaderBox(timescale: 600, duration: 600)
        let tkhd = makeTrackHeaderBox(trackID: 3, duration: 600, width: 0, height: 0)
        let mdhd = makeMediaHeaderBox(timescale: 48_000, duration: 48_000)
        let elst = makeEditListBox(entries: [
            .init(segmentDuration: 600, mediaTime: 0, mediaRateInteger: -1, mediaRateFraction: 0),
            .init(segmentDuration: 0, mediaTime: 0, mediaRateInteger: 1, mediaRateFraction: 1)
        ])
        let mdia = makeContainer(type: ContainerTypes.media, children: [mdhd])
        let edts = makeContainer(type: FourCharContainerCode.edts.rawValue, children: [elst])
        let trak = makeContainer(type: ContainerTypes.track, children: [tkhd, mdia, edts])
        let moov = makeContainer(type: ContainerTypes.movie, children: [mvhd, trak])

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let editListEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "elst"
            }
            return false
        })

        let issues = editListEvent.validationIssues.filter { $0.ruleID == "VR-014" }
        XCTAssertEqual(issues.count, 2)
        XCTAssertTrue(issues.contains(where: { $0.message.contains("reverse playback") }))
        XCTAssertTrue(issues.contains(where: { $0.message.contains("media_rate_fraction") }))
    }

    func testSampleTableValidationPassesForMatchingTables() async throws {
        let tkhd = makeTrackHeaderBox(trackID: 5, duration: 900, width: 0, height: 0)
        let stts = makeTimeToSampleBox(entries: [
            TimeToSampleEntryParameters(sampleCount: 3, sampleDelta: 300),
            TimeToSampleEntryParameters(sampleCount: 5, sampleDelta: 300)
        ])
        let ctts = makeCompositionOffsetBox(entries: [
            CompositionOffsetEntryParameters(sampleCount: 3, sampleOffset: 0),
            CompositionOffsetEntryParameters(sampleCount: 5, sampleOffset: 0)
        ])
        let stsc = makeSampleToChunkBox(entries: [
            SampleToChunkEntryParameters(firstChunk: 1, samplesPerChunk: 2, sampleDescriptionIndex: 1),
            SampleToChunkEntryParameters(firstChunk: 3, samplesPerChunk: 4, sampleDescriptionIndex: 1)
        ])
        let stsz = makeSampleSizeBox(defaultSampleSize: 128, sampleCount: 8)
        let stco = makeChunkOffsetBox(offsets: [100, 200, 320])
        let stbl = makeContainer(
            type: FourCharContainerCode.stbl.rawValue,
            children: [stts, ctts, stsc, stsz, stco]
        )
        let minf = makeContainer(type: FourCharContainerCode.minf.rawValue, children: [stbl])
        let mdia = makeContainer(type: ContainerTypes.media, children: [minf])
        let trak = makeContainer(type: ContainerTypes.track, children: [tkhd, mdia])
        let moov = makeContainer(type: ContainerTypes.movie, children: [trak])

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        for code in ["stsc", "stsz", "stco"] {
            let event = try XCTUnwrap(events.first { event in
                if case let .willStartBox(header, _) = event.kind {
                    return header.type.rawValue == code
                }
                return false
            })
            let issues = event.validationIssues.filter { $0.ruleID == "VR-015" }
            XCTAssertTrue(issues.isEmpty, "Expected no VR-015 issues for \(code)")
        }
    }

    func testSampleTableValidationReportsSampleCountMismatch() async throws {
        let tkhd = makeTrackHeaderBox(trackID: 6, duration: 1_200, width: 0, height: 0)
        let stsc = makeSampleToChunkBox(entries: [
            SampleToChunkEntryParameters(firstChunk: 1, samplesPerChunk: 2, sampleDescriptionIndex: 1),
            SampleToChunkEntryParameters(firstChunk: 3, samplesPerChunk: 4, sampleDescriptionIndex: 1)
        ])
        let stsz = makeSampleSizeBox(defaultSampleSize: 256, sampleCount: 7)
        let stco = makeChunkOffsetBox(offsets: [64, 128, 256])
        let stbl = makeContainer(type: FourCharContainerCode.stbl.rawValue, children: [stsc, stsz, stco])
        let minf = makeContainer(type: FourCharContainerCode.minf.rawValue, children: [stbl])
        let mdia = makeContainer(type: ContainerTypes.media, children: [minf])
        let trak = makeContainer(type: ContainerTypes.track, children: [tkhd, mdia])
        let moov = makeContainer(type: ContainerTypes.movie, children: [trak])

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let issues = events.flatMap { event in
            event.validationIssues.filter { $0.ruleID == "VR-015" }
        }

        XCTAssertFalse(issues.isEmpty)
        XCTAssertTrue(issues.contains { $0.message.contains("declares 7 samples") })
    }

    func testSampleTableValidationReportsNonMonotonicChunkOffsets() async throws {
        let tkhd = makeTrackHeaderBox(trackID: 7, duration: 900, width: 0, height: 0)
        let stsc = makeSampleToChunkBox(entries: [
            SampleToChunkEntryParameters(firstChunk: 1, samplesPerChunk: 2, sampleDescriptionIndex: 1),
            SampleToChunkEntryParameters(firstChunk: 3, samplesPerChunk: 4, sampleDescriptionIndex: 1)
        ])
        let stsz = makeSampleSizeBox(defaultSampleSize: 128, sampleCount: 8)
        let stco = makeChunkOffsetBox(offsets: [400, 392, 512])
        let stbl = makeContainer(type: FourCharContainerCode.stbl.rawValue, children: [stsc, stsz, stco])
        let minf = makeContainer(type: FourCharContainerCode.minf.rawValue, children: [stbl])
        let mdia = makeContainer(type: ContainerTypes.media, children: [minf])
        let trak = makeContainer(type: ContainerTypes.track, children: [tkhd, mdia])
        let moov = makeContainer(type: ContainerTypes.movie, children: [trak])

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let chunkOffsetEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "stco"
            }
            return false
        })

        let issues = chunkOffsetEvent.validationIssues.filter { $0.ruleID == "VR-015" }
        XCTAssertEqual(issues.count, 1)
        XCTAssertTrue(issues.contains { $0.message.contains("non-monotonic") })
    }

    func testSampleTableValidationReportsTimeToSampleMismatch() async throws {
        let tkhd = makeTrackHeaderBox(trackID: 8, duration: 900, width: 0, height: 0)
        let stts = makeTimeToSampleBox(entries: [
            TimeToSampleEntryParameters(sampleCount: 3, sampleDelta: 200),
            TimeToSampleEntryParameters(sampleCount: 4, sampleDelta: 200)
        ])
        let stsc = makeSampleToChunkBox(entries: [
            SampleToChunkEntryParameters(firstChunk: 1, samplesPerChunk: 2, sampleDescriptionIndex: 1),
            SampleToChunkEntryParameters(firstChunk: 3, samplesPerChunk: 4, sampleDescriptionIndex: 1)
        ])
        let stsz = makeSampleSizeBox(defaultSampleSize: 160, sampleCount: 8)
        let stco = makeChunkOffsetBox(offsets: [96, 256, 448])
        let stbl = makeContainer(type: FourCharContainerCode.stbl.rawValue, children: [stts, stsc, stsz, stco])
        let minf = makeContainer(type: FourCharContainerCode.minf.rawValue, children: [stbl])
        let mdia = makeContainer(type: ContainerTypes.media, children: [minf])
        let trak = makeContainer(type: ContainerTypes.track, children: [tkhd, mdia])
        let moov = makeContainer(type: ContainerTypes.movie, children: [trak])

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let sampleSizeEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "stsz"
            }
            return false
        })

        let issues = sampleSizeEvent.validationIssues.filter { $0.ruleID == "VR-015" }
        XCTAssertFalse(issues.isEmpty)
        XCTAssertTrue(issues.contains { issue in
            issue.message.contains("time-to-sample table")
        })
    }

    func testSampleTableValidationReportsCompositionOffsetMismatch() async throws {
        let tkhd = makeTrackHeaderBox(trackID: 9, duration: 900, width: 0, height: 0)
        let stts = makeTimeToSampleBox(entries: [
            TimeToSampleEntryParameters(sampleCount: 4, sampleDelta: 300),
            TimeToSampleEntryParameters(sampleCount: 4, sampleDelta: 300)
        ])
        let ctts = makeCompositionOffsetBox(entries: [
            CompositionOffsetEntryParameters(sampleCount: 4, sampleOffset: 0),
            CompositionOffsetEntryParameters(sampleCount: 5, sampleOffset: 0)
        ])
        let stsc = makeSampleToChunkBox(entries: [
            SampleToChunkEntryParameters(firstChunk: 1, samplesPerChunk: 2, sampleDescriptionIndex: 1),
            SampleToChunkEntryParameters(firstChunk: 3, samplesPerChunk: 4, sampleDescriptionIndex: 1)
        ])
        let stsz = makeSampleSizeBox(defaultSampleSize: 256, sampleCount: 8)
        let stco = makeChunkOffsetBox(offsets: [128, 320, 512])
        let stbl = makeContainer(type: FourCharContainerCode.stbl.rawValue, children: [stts, ctts, stsc, stsz, stco])
        let minf = makeContainer(type: FourCharContainerCode.minf.rawValue, children: [stbl])
        let mdia = makeContainer(type: ContainerTypes.media, children: [minf])
        let trak = makeContainer(type: ContainerTypes.track, children: [tkhd, mdia])
        let moov = makeContainer(type: ContainerTypes.movie, children: [trak])

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let sampleSizeEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "stsz"
            }
            return false
        })

        let stszIssues = sampleSizeEvent.validationIssues.filter { $0.ruleID == "VR-015" }
        XCTAssertFalse(stszIssues.isEmpty)
        XCTAssertTrue(stszIssues.contains { issue in
            issue.message.contains("composition offset table")
        })

        let cttsEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "ctts"
            }
            return false
        })

        let cttsIssues = cttsEvent.validationIssues.filter { $0.ruleID == "VR-015" }
        XCTAssertFalse(cttsIssues.isEmpty)
        XCTAssertTrue(cttsIssues.contains { issue in
            issue.message.contains("composition offset table")
        })
    }

    func testSampleTableValidationReportsTimeToSampleAndCompositionMismatch() async throws {
        let tkhd = makeTrackHeaderBox(trackID: 10, duration: 900, width: 0, height: 0)
        let stts = makeTimeToSampleBox(entries: [
            TimeToSampleEntryParameters(sampleCount: 5, sampleDelta: 250),
            TimeToSampleEntryParameters(sampleCount: 3, sampleDelta: 250)
        ])
        let ctts = makeCompositionOffsetBox(entries: [
            CompositionOffsetEntryParameters(sampleCount: 4, sampleOffset: 0),
            CompositionOffsetEntryParameters(sampleCount: 5, sampleOffset: 0)
        ])
        let stsc = makeSampleToChunkBox(entries: [
            SampleToChunkEntryParameters(firstChunk: 1, samplesPerChunk: 2, sampleDescriptionIndex: 1),
            SampleToChunkEntryParameters(firstChunk: 3, samplesPerChunk: 4, sampleDescriptionIndex: 1)
        ])
        let stsz = makeSampleSizeBox(defaultSampleSize: 192, sampleCount: 8)
        let stco = makeChunkOffsetBox(offsets: [96, 256, 448])
        let stbl = makeContainer(type: FourCharContainerCode.stbl.rawValue, children: [stts, ctts, stsc, stsz, stco])
        let minf = makeContainer(type: FourCharContainerCode.minf.rawValue, children: [stbl])
        let mdia = makeContainer(type: ContainerTypes.media, children: [minf])
        let trak = makeContainer(type: ContainerTypes.track, children: [tkhd, mdia])
        let moov = makeContainer(type: ContainerTypes.movie, children: [trak])

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let sampleSizeEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "stsz"
            }
            return false
        })

        let stszIssues = sampleSizeEvent.validationIssues.filter { $0.ruleID == "VR-015" }
        XCTAssertFalse(stszIssues.isEmpty)
        XCTAssertTrue(stszIssues.contains { issue in
            issue.message.contains("composition offset table")
        })

        let cttsEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "ctts"
            }
            return false
        })

        let cttsIssues = cttsEvent.validationIssues.filter { $0.ruleID == "VR-015" }
        XCTAssertFalse(cttsIssues.isEmpty)
        XCTAssertTrue(cttsIssues.contains { issue in
            issue.message.contains("composition offset table")
        })
    }

    func testLivePipelineReportsVersionAndFlagMismatchWarnings() async throws {
        let mismatchTkhd = makeBox(
            type: "tkhd",
            payload: Data([0x01, 0x00, 0x00, 0x00]) + Data(repeating: 0, count: 28)
        )
        let trak = makeBox(type: ContainerTypes.track, payload: mismatchTkhd)
        let moov = makeBox(type: ContainerTypes.movie, payload: trak)
        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let tkhdEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "tkhd"
            }
            return false
        }))

        let mismatches = tkhdEvent.validationIssues.filter { $0.ruleID == "VR-003" }
        XCTAssertEqual(mismatches.count, 2)
        XCTAssertTrue(mismatches.allSatisfy { $0.severity == .warning })
        XCTAssertTrue(mismatches.contains(where: { $0.message.contains("version") }))
        XCTAssertTrue(mismatches.contains(where: { $0.message.contains("flags") }))
    }

    func testTolerantModeEmitsParseIssuesForValidationWarnings() async throws {
        let mismatchTkhd = makeBox(
            type: "tkhd",
            payload: Data([0x01, 0x00, 0x00, 0x00]) + Data(repeating: 0, count: 28)
        )
        let trak = makeBox(type: ContainerTypes.track, payload: mismatchTkhd)
        let moov = makeBox(type: ContainerTypes.movie, payload: trak)
        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live(options: .tolerant)
        let store = ParseIssueStore()
        let context = ParsePipeline.Context(options: .tolerant, issueStore: store)

        let events = try await collectEvents(from: pipeline.events(for: reader, context: context))
        let tkhdEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "tkhd"
            }
            return false
        }))

        let mismatches = tkhdEvent.validationIssues.filter { $0.ruleID == "VR-003" }
        XCTAssertEqual(mismatches.count, 2)

        let parseIssues = tkhdEvent.issues.filter { $0.code == "VR-003" }
        XCTAssertEqual(parseIssues.count, 2)
        XCTAssertTrue(parseIssues.allSatisfy { $0.severity == .warning })
        XCTAssertTrue(parseIssues.contains(where: { $0.message.contains("version") }))
        XCTAssertTrue(parseIssues.contains(where: { $0.message.contains("flags") }))

        await MainActor.run {}
        let storedIssues = store.issues.filter { $0.code == "VR-003" }
        XCTAssertEqual(storedIssues.count, 2)
    }

    func testLivePipelineLeavesMatchingVersionAndFlagsUnchanged() async throws {
        let matchingTkhd = makeBox(
            type: "tkhd",
            payload: Data([0x00, 0x00, 0x00, 0x07]) + Data(repeating: 0, count: 28)
        )
        let trak = makeBox(type: ContainerTypes.track, payload: matchingTkhd)
        let moov = makeBox(type: ContainerTypes.movie, payload: trak)
        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let tkhdEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "tkhd"
            }
            return false
        }))

        let vr003Issues = tkhdEvent.validationIssues.filter { $0.ruleID == "VR-003" }
        XCTAssertTrue(vr003Issues.isEmpty)
    }

    func testLivePipelineEmitsResearchIssueForUnknownBoxes() async throws {
        let unknown = makeBox(type: "zzzz", payload: Data(count: 4))
        let reader = InMemoryRandomAccessReader(data: unknown)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let unknownEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "zzzz"
            }
            return false
        }))

        let researchIssues = unknownEvent.validationIssues.filter { $0.ruleID == "VR-006" }
        XCTAssertEqual(researchIssues.count, 1)
        XCTAssertEqual(researchIssues.first?.severity, .info)
        XCTAssertTrue(researchIssues.first?.message.contains("zzzz") ?? false)
    }

    func testLivePipelineAppendsUnknownBoxesToResearchLog() async throws {
        let unknown = makeBox(type: "zzzz", payload: Data(count: 8))
        let reader = InMemoryRandomAccessReader(data: unknown)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let logURL = directory.appendingPathComponent("research-log.json")
        let log = try ResearchLogWriter(fileURL: logURL)
        let pipeline = ParsePipeline.live(researchLog: log)

        _ = try await collectEvents(from: pipeline.events(for: reader, context: .init(source: URL(fileURLWithPath: "/tmp/sample.mp4"))))

        let entries = log.loadEntries()
        XCTAssertEqual(entries.count, 1)
        let entry = try XCTUnwrap(entries.first)
        XCTAssertEqual(entry.boxType, "zzzz")
        XCTAssertEqual(entry.filePath, "/tmp/sample.mp4")
        XCTAssertEqual(entry.startOffset, 0)
        XCTAssertEqual(entry.endOffset, Int64(unknown.count))
    }

    func testLivePipelineReportsErrorWhenMediaAppearsBeforeFileType() async throws {
        let moov = makeBox(type: ContainerTypes.movie, payload: Data())
        let mdat = makeBox(type: MediaAndIndexBoxCode.mediaData.rawValue, payload: Data(count: 8))
        let reader = InMemoryRandomAccessReader(data: moov + mdat)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        let offendingEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == ContainerTypes.movie
            }
            return false
        }))

        let vr004Issues = offendingEvent.validationIssues.filter { $0.ruleID == "VR-004" }
        XCTAssertEqual(vr004Issues.count, 1)
        XCTAssertEqual(vr004Issues.first?.severity, .error)
        XCTAssertTrue(vr004Issues.first?.message.contains("ftyp") ?? false)
    }

    func testLivePipelineWarnsWhenMovieDataPrecedesMovieBox() async throws {
        let ftyp = makeBox(type: "ftyp", payload: Data(count: 16))
        let mdat = makeBox(type: MediaAndIndexBoxCode.mediaData.rawValue, payload: Data(count: 8))
        let moov = makeBox(type: ContainerTypes.movie, payload: Data())
        let reader = InMemoryRandomAccessReader(data: ftyp + mdat + moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let mdatEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return MediaAndIndexBoxCode.isMediaPayload(header)
            }
            return false
        }))

        let vr005Issues = mdatEvent.validationIssues.filter { $0.ruleID == "VR-005" }
        XCTAssertEqual(vr005Issues.count, 1)
        XCTAssertEqual(vr005Issues.first?.severity, .warning)
        XCTAssertTrue(vr005Issues.first?.message.contains(ContainerTypes.movie) ?? false)
    }

    func testLivePipelineAllowsEarlyMovieDataWhenStreamingLayoutDetected() async throws {
        let ftyp = makeBox(type: "ftyp", payload: Data(count: 16))
        let moof = makeBox(type: ContainerTypes.movieFragment, payload: Data())
        let mdat = makeBox(type: MediaAndIndexBoxCode.mediaData.rawValue, payload: Data(count: 8))
        let moov = makeBox(type: ContainerTypes.movie, payload: Data())
        let reader = InMemoryRandomAccessReader(data: ftyp + moof + mdat + moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let mdatEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, _) = event.kind {
                return MediaAndIndexBoxCode.isMediaPayload(header)
            }
            return false
        }))

        let vr005Issues = mdatEvent.validationIssues.filter { $0.ruleID == "VR-005" }
        XCTAssertTrue(vr005Issues.isEmpty)
    }

    func testLivePipelineDoesNotWarnForCommonTopLevelOrdering() async throws {
        let ftyp = makeBox(type: "ftyp", payload: Data(count: 16))
        let moov = makeBox(type: ContainerTypes.movie, payload: Data())
        let mdat = makeBox(type: MediaAndIndexBoxCode.mediaData.rawValue, payload: Data(count: 8))
        let reader = InMemoryRandomAccessReader(data: ftyp + moov + mdat)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        let ftypEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, depth) = event.kind {
                return depth == 0 && header.type.rawValue == "ftyp"
            }
            return false
        }))
        let moovEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, depth) = event.kind {
                return depth == 0 && header.type.rawValue == ContainerTypes.movie
            }
            return false
        }))

        XCTAssertTrue(ftypEvent.validationIssues.filter { $0.ruleID == "E3" }.isEmpty)
        XCTAssertTrue(moovEvent.validationIssues.filter { $0.ruleID == "E3" }.isEmpty)
    }

    func testLivePipelineAdvisesWhenFileTypeIsNotFirstTopLevelBox() async throws {
        let junk = makeBox(type: "zzzz", payload: Data(count: 4))
        let ftyp = makeBox(type: "ftyp", payload: Data(count: 16))
        let moov = makeBox(type: ContainerTypes.movie, payload: Data())
        let reader = InMemoryRandomAccessReader(data: junk + ftyp + moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        let ftypEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, depth) = event.kind {
                return depth == 0 && header.type.rawValue == "ftyp"
            }
            return false
        }))

        let advisoryIssues = ftypEvent.validationIssues.filter { $0.ruleID == "E3" }
        XCTAssertEqual(advisoryIssues.count, 1)
        XCTAssertEqual(advisoryIssues.first?.severity, .warning)
        XCTAssertTrue(advisoryIssues.first?.message.contains("ftyp") ?? false)
    }

    func testLivePipelineAdvisesWhenMovieFollowsStreamingMediaPayload() async throws {
        let ftyp = makeBox(type: "ftyp", payload: Data(count: 16))
        let styp = makeBox(type: MediaAndIndexBoxCode.segmentType.rawValue, payload: Data(count: 8))
        let moof = makeBox(type: ContainerTypes.movieFragment, payload: Data())
        let mdat = makeBox(type: MediaAndIndexBoxCode.mediaData.rawValue, payload: Data(count: 8))
        let moov = makeBox(type: ContainerTypes.movie, payload: Data())
        let reader = InMemoryRandomAccessReader(data: ftyp + styp + moof + mdat + moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))

        let moovEvent = try XCTUnwrap(events.first(where: { event in
            if case let .willStartBox(header, depth) = event.kind {
                return depth == 0 && header.type.rawValue == ContainerTypes.movie
            }
            return false
        }))

        let advisoryIssues = moovEvent.validationIssues.filter { $0.ruleID == "E3" }
        XCTAssertEqual(advisoryIssues.count, 1)
        XCTAssertEqual(advisoryIssues.first?.severity, .warning)
        XCTAssertTrue(advisoryIssues.first?.message.contains(ContainerTypes.movie) ?? false)
        XCTAssertTrue(advisoryIssues.first?.message.contains(MediaAndIndexBoxCode.mediaData.rawValue) ?? false)
    }

    func testLivePipelineParsesMovieFragmentHeaderSequenceNumber() async throws {
        let mfhd = makeMovieFragmentHeaderBox(sequenceNumber: 42)
        let moof = makeContainer(type: ContainerTypes.movieFragment, children: [mfhd])
        let reader = InMemoryRandomAccessReader(data: moof)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let mfhdEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "mfhd"
            }
            return false
        })

        let payload = try XCTUnwrap(mfhdEvent.payload)
        XCTAssertEqual(field(named: "sequence_number", in: payload), "42")

        let detail = try XCTUnwrap(payload.movieFragmentHeader)
        XCTAssertEqual(detail.sequenceNumber, 42)
    }

    func testLivePipelineAggregatesTrackFragmentSummary() async throws {
        let tfhd = makeTrackFragmentHeaderBox(
            trackID: 1,
            baseDataOffset: 4096,
            defaultSampleDuration: 100,
            defaultSampleSize: 512,
            defaultSampleFlags: 0
        )
        let tfdt = makeTrackFragmentDecodeTimeBox(baseDecodeTime: 1200)
        let trun = makeTrackRunBox(
            sampleCount: 2,
            dataOffset: 256,
            sampleDurations: [110, 120],
            sampleSizes: [500, 600]
        )
        let traf = makeBox(type: ContainerTypes.trackFragment, payload: tfhd + tfdt + trun)
        let mfhd = makeMovieFragmentHeaderBox(sequenceNumber: 1)
        let moof = makeContainer(type: ContainerTypes.movieFragment, children: [mfhd, traf])

        let reader = InMemoryRandomAccessReader(data: moof)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let trafFinish = try XCTUnwrap(events.first { event in
            guard case let .didFinishBox(header, _) = event.kind else { return false }
            return header.type.rawValue == ContainerTypes.trackFragment
        })

        let summary = try XCTUnwrap(trafFinish.payload?.trackFragment)
        XCTAssertEqual(summary.trackID, 1)
        XCTAssertEqual(summary.sampleDescriptionIndex, 1)
        XCTAssertEqual(summary.baseDataOffset, 4096)
        XCTAssertEqual(summary.totalSampleCount, 2)
        XCTAssertEqual(summary.totalSampleDuration, 230)
        XCTAssertEqual(summary.totalSampleSize, 1100)
        XCTAssertEqual(summary.baseDecodeTime, 1200)
        XCTAssertEqual(summary.runs.count, 1)
        let run = try XCTUnwrap(summary.runs.first)
        XCTAssertEqual(run.sampleCount, 2)
        XCTAssertEqual(run.dataOffset, 256)
        XCTAssertEqual(run.totalSampleDuration, 230)
        XCTAssertEqual(run.totalSampleSize, 1100)
        XCTAssertEqual(run.entries.count, 2)
        XCTAssertEqual(run.entries.first?.sampleDuration, 110)
        XCTAssertEqual(run.entries.last?.sampleDuration, 120)
    }

    func testLivePipelineParsesHandlerBoxPayload() async throws {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // pre-defined
        payload.append(contentsOf: "mdir".utf8) // handler type (metadata)
        payload.append(contentsOf: Data(count: 12)) // reserved
        payload.append(contentsOf: "Metadata Handler".utf8)
        payload.append(0x00) // null terminator

        let hdlr = makeBox(type: "hdlr", payload: payload)
        let mdia = makeBox(type: "mdia", payload: hdlr)
        let trak = makeBox(type: ContainerTypes.track, payload: mdia)
        let moov = makeBox(type: ContainerTypes.movie, payload: trak)

        let reader = InMemoryRandomAccessReader(data: moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let handlerEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "hdlr"
            }
            return false
        })

        let parsed = try XCTUnwrap(handlerEvent.payload)
        XCTAssertEqual(parsed.fields.first { $0.name == "handler_type" }?.value, "mdir")
        XCTAssertEqual(parsed.fields.first { $0.name == "handler_category" }?.value, "Metadata")
        XCTAssertEqual(parsed.fields.first { $0.name == "handler_name" }?.value, "Metadata Handler")
    }

    func testLivePipelineParsesMetadataHierarchy() async throws {
        let metadataHierarchy = makeMetadataContainer()
        let moov = makeContainer(type: ContainerTypes.movie, children: [metadataHierarchy])
        let ftyp = makeBox(type: "ftyp", payload: Data(count: 16))
        let reader = InMemoryRandomAccessReader(data: ftyp + moov)
        let pipeline = ParsePipeline.live()

        let events = try await collectEvents(from: pipeline.events(for: reader))
        let ilstEvent = try XCTUnwrap(events.first { event in
            if case let .willStartBox(header, _) = event.kind {
                return header.type.rawValue == "ilst"
            }
            return false
        })

        let parsed = try XCTUnwrap(ilstEvent.payload)
        XCTAssertEqual(field(named: "handler_type", in: parsed), "mdir")
        XCTAssertEqual(field(named: "entries[0].identifier", in: parsed), "©nam")
        XCTAssertEqual(field(named: "entries[0].values[0].value", in: parsed), "Example Title")
        XCTAssertEqual(field(named: "entries[1].identifier", in: parsed), "key[1]")
        XCTAssertEqual(field(named: "entries[1].name", in: parsed), "com.example.rating")
        XCTAssertEqual(field(named: "entries[1].values[0].value", in: parsed), "120")

        let detail = try XCTUnwrap(parsed.metadataItemList)
        XCTAssertEqual(detail.handlerType?.rawValue, "mdir")
        XCTAssertEqual(detail.entries.count, 2)
        XCTAssertEqual(detail.entries[0].values.first?.kind, .utf8("Example Title"))
        XCTAssertEqual(detail.entries[1].values.first?.kind, .integer(120))
    }

    private func collectEvents(from stream: ParsePipeline.EventStream) async throws -> [ParseEvent] {
        var result: [ParseEvent] = []
        for try await event in stream {
            result.append(event)
        }
        return result
    }

    private func field(named name: String, in payload: ParsedBoxPayload) -> String? {
        payload.fields.first(where: { $0.name == name })?.value
    }

    private func makeMovieHeaderBox(timescale: UInt32, duration: UInt32) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // creation time
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // modification time
        payload.append(contentsOf: timescale.bigEndianBytes)
        payload.append(contentsOf: duration.bigEndianBytes)
        payload.append(contentsOf: UInt32(0x0001_0000).bigEndianBytes) // rate 1.0
        payload.append(contentsOf: UInt16(0x0100).bigEndianBytes) // volume 1.0
        payload.append(contentsOf: Data(count: 10)) // reserved
        payload.append(contentsOf: Int32(0x0001_0000).bigEndianBytes) // matrix.a
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.b
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.u
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.c
        payload.append(contentsOf: Int32(0x0001_0000).bigEndianBytes) // matrix.d
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.v
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.x
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.y
        payload.append(contentsOf: Int32(0x4000_0000).bigEndianBytes) // matrix.w
        payload.append(contentsOf: Data(count: 24)) // pre-defined
        payload.append(contentsOf: UInt32(2).bigEndianBytes) // next track ID
        return makeBox(type: "mvhd", payload: payload)
    }

    private func makeTrackHeaderBox(trackID: UInt32, duration: UInt32, width: UInt32, height: UInt32) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x07]) // flags (enabled + in movie + in preview)
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // creation time
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // modification time
        payload.append(contentsOf: trackID.bigEndianBytes)
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // reserved
        payload.append(contentsOf: duration.bigEndianBytes)
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // reserved
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // reserved
        payload.append(contentsOf: Int16(0).bigEndianBytes) // layer
        payload.append(contentsOf: Int16(0).bigEndianBytes) // alternate group
        payload.append(contentsOf: UInt16(0).bigEndianBytes) // volume (0 for video)
        payload.append(contentsOf: UInt16(0).bigEndianBytes) // reserved
        payload.append(contentsOf: Int32(0x0001_0000).bigEndianBytes) // matrix.a
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.b
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.u
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.c
        payload.append(contentsOf: Int32(0x0001_0000).bigEndianBytes) // matrix.d
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.v
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.x
        payload.append(contentsOf: Int32(0).bigEndianBytes) // matrix.y
        payload.append(contentsOf: Int32(0x4000_0000).bigEndianBytes) // matrix.w
        payload.append(contentsOf: UInt32(width << 16).bigEndianBytes)
        payload.append(contentsOf: UInt32(height << 16).bigEndianBytes)
        return makeBox(type: "tkhd", payload: payload)
    }

    private func makeMediaHeaderBox(timescale: UInt32, duration: UInt32) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // creation time
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // modification time
        payload.append(contentsOf: timescale.bigEndianBytes)
        payload.append(contentsOf: duration.bigEndianBytes)
        payload.append(contentsOf: languageBytes("eng"))
        payload.append(contentsOf: UInt16(0).bigEndianBytes) // pre-defined
        return makeBox(type: "mdhd", payload: payload)
    }

    private struct EditListEntryParameters {
        let segmentDuration: UInt32
        let mediaTime: Int32
        let mediaRateInteger: Int16
        let mediaRateFraction: UInt16
    }

    private func makeEditListBox(
        version: UInt8 = 0,
        entries: [EditListEntryParameters]
    ) -> Data {
        var payload = Data()
        payload.append(version)
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)
        for entry in entries {
            if version == 1 {
                payload.append(contentsOf: UInt64(entry.segmentDuration).bigEndianBytes)
                payload.append(contentsOf: Int64(entry.mediaTime).bigEndianBytes)
            } else {
                payload.append(contentsOf: entry.segmentDuration.bigEndianBytes)
                payload.append(contentsOf: entry.mediaTime.bigEndianBytes)
            }
            payload.append(contentsOf: entry.mediaRateInteger.bigEndianBytes)
            payload.append(contentsOf: entry.mediaRateFraction.bigEndianBytes)
        }
        return makeBox(type: "elst", payload: payload)
    }

    private final class PayloadSpyRandomAccessReader: RandomAccessReader {
        private let reader: InMemoryRandomAccessReader
        private let payloadRange: Range<Int64>
        private(set) var readRanges: [Range<Int64>] = []

        init(data: Data, payloadRange: Range<Int64>) {
            self.reader = InMemoryRandomAccessReader(data: data)
            self.payloadRange = payloadRange
        }

        var length: Int64 { reader.length }

        var didReadPayload: Bool {
            readRanges.contains { $0.overlaps(payloadRange) }
        }

        func read(at offset: Int64, count: Int) throws -> Data {
            let data = try reader.read(at: offset, count: count)
            if !data.isEmpty {
                let range = offset..<offset + Int64(data.count)
                readRanges.append(range)
            }
            return data
        }
    }

    private func makeContainer(type: String, children: [Data]) -> Data {
        let payload = children.reduce(into: Data()) { result, child in
            result.append(child)
        }
        return makeBox(type: type, payload: payload)
    }

    private enum EventKind {
        case willStart
        case didFinish
    }

    private func assertEvent(
        _ event: ParseEvent,
        kind expectedKind: EventKind,
        type expectedType: String,
        depth expectedDepth: Int,
        offset expectedOffset: Int64
    ) throws {
        let type = try IIFourCharCode(expectedType)
        switch (event.kind, expectedKind) {
        case let (.willStartBox(header, depth), .willStart):
            XCTAssertEqual(header.type, type)
            XCTAssertEqual(depth, expectedDepth)
            XCTAssertEqual(event.offset, expectedOffset)
        case let (.didFinishBox(header, depth), .didFinish):
            XCTAssertEqual(header.type, type)
            XCTAssertEqual(depth, expectedDepth)
            XCTAssertEqual(event.offset, expectedOffset)
        default:
            XCTFail("Unexpected event kind: \(event.kind)")
        }
    }

    private func makeBox(type: String, payload: Data, useLargeSize: Bool = false) -> Data {
        precondition(type.utf8.count == 4, "Box type must be four characters")
        var data = Data()
        let payloadCount = payload.count
        if useLargeSize {
            let headerSize = 16
            let totalSize = headerSize + payloadCount
            data.append(contentsOf: UInt32(1).bigEndianBytes)
            data.append(contentsOf: type.utf8)
            data.append(contentsOf: UInt64(totalSize).bigEndianBytes)
        } else {
            let totalSize = 8 + payloadCount
            data.append(contentsOf: UInt32(totalSize).bigEndianBytes)
            data.append(contentsOf: type.utf8)
        }
        data.append(payload)
        return data
    }

    private func makeMetadataContainer() -> Data {
        let handler = makeMetadataHandlerBox()
        let keys = makeMetadataKeysBox(entries: [
            (namespace: "mdta", name: "com.example.rating")
        ])
        let ilst = makeMetadataItemListBox(entries: [
            MetadataItemBoxEntry(
                identifier: [0xA9, 0x6E, 0x61, 0x6D],
                type: 1,
                locale: 0,
                data: Data("Example Title".utf8)
            ),
            MetadataItemBoxEntry(
                identifier: [0x00, 0x00, 0x00, 0x01],
                type: 21,
                locale: 0,
                data: Data(UInt16(120).bigEndianBytes)
            )
        ])

        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // reserved
        payload.append(handler)
        payload.append(keys)
        payload.append(ilst)

        let meta = makeBox(type: "meta", payload: payload)
        return makeBox(type: "udta", payload: meta)
    }

    private func makeMetadataHandlerBox() -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // pre-defined
        payload.append(contentsOf: "mdir".utf8) // metadata handler
        payload.append(contentsOf: Data(count: 12)) // reserved
        payload.append(contentsOf: "Metadata Handler".utf8)
        payload.append(0x00)
        return makeBox(type: "hdlr", payload: payload)
    }

    private func makeMetadataKeysBox(entries: [(namespace: String, name: String)]) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)

        for entry in entries {
            let nameData = Data(entry.name.utf8)
            var entryData = Data()
            entryData.append(contentsOf: entry.namespace.utf8)
            entryData.append(nameData)
            payload.append(contentsOf: UInt32(entryData.count).bigEndianBytes)
            payload.append(entryData)
        }

        return makeBox(type: "keys", payload: payload)
    }

    private struct MetadataItemBoxEntry {
        let identifier: [UInt8]
        let type: UInt32
        let locale: UInt32
        let data: Data
    }

    private func makeMetadataItemListBox(entries: [MetadataItemBoxEntry]) -> Data {
        var payload = Data()
        for entry in entries {
            payload.append(makeMetadataItemEntry(
                identifierBytes: entry.identifier,
                dataBox: makeMetadataDataBox(type: entry.type, locale: entry.locale, data: entry.data)
            ))
        }
        return makeBox(type: "ilst", payload: payload)
    }

    private func makeMovieFragmentHeaderBox(sequenceNumber: UInt32) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: sequenceNumber.bigEndianBytes)
        return makeBox(type: "mfhd", payload: payload)
    }

    private func makeTrackFragmentHeaderBox(
        trackID: UInt32,
        baseDataOffset: UInt64,
        defaultSampleDuration: UInt32,
        defaultSampleSize: UInt32,
        defaultSampleFlags: UInt32
    ) -> Data {
        let flags: UInt32 = 0x000001 | 0x000008 | 0x000010 | 0x000020
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: UInt32(flags).bigEndianFlagBytes)
        payload.append(contentsOf: trackID.bigEndianBytes)
        payload.append(contentsOf: baseDataOffset.bigEndianBytes)
        payload.append(contentsOf: defaultSampleDuration.bigEndianBytes)
        payload.append(contentsOf: defaultSampleSize.bigEndianBytes)
        payload.append(contentsOf: defaultSampleFlags.bigEndianBytes)
        return makeBox(type: "tfhd", payload: payload)
    }

    private func makeTrackFragmentDecodeTimeBox(baseDecodeTime: UInt64) -> Data {
        var payload = Data()
        payload.append(0x01) // version 1 for 64-bit decode time
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: baseDecodeTime.bigEndianBytes)
        return makeBox(type: "tfdt", payload: payload)
    }

    private func makeTrackRunBox(
        sampleCount: UInt32,
        dataOffset: Int32,
        sampleDurations: [UInt32],
        sampleSizes: [UInt32]
    ) -> Data {
        precondition(sampleDurations.count == sampleSizes.count)
        precondition(sampleDurations.count == Int(sampleCount))
        let flags: UInt32 = 0x000001 | 0x000100 | 0x000200
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: flags.bigEndianFlagBytes)
        payload.append(contentsOf: sampleCount.bigEndianBytes)
        payload.append(contentsOf: dataOffset.bigEndianBytes)
        for index in 0..<sampleDurations.count {
            payload.append(contentsOf: sampleDurations[index].bigEndianBytes)
            payload.append(contentsOf: sampleSizes[index].bigEndianBytes)
        }
        return makeBox(type: "trun", payload: payload)
    }

    private struct SampleToChunkEntryParameters {
        let firstChunk: UInt32
        let samplesPerChunk: UInt32
        let sampleDescriptionIndex: UInt32
    }

    private struct TimeToSampleEntryParameters {
        let sampleCount: UInt32
        let sampleDelta: UInt32
    }

    private struct CompositionOffsetEntryParameters {
        let sampleCount: UInt32
        let sampleOffset: Int32
    }

    private func makeSampleToChunkBox(entries: [SampleToChunkEntryParameters]) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)
        for entry in entries {
            payload.append(contentsOf: entry.firstChunk.bigEndianBytes)
            payload.append(contentsOf: entry.samplesPerChunk.bigEndianBytes)
            payload.append(contentsOf: entry.sampleDescriptionIndex.bigEndianBytes)
        }
        return makeBox(type: "stsc", payload: payload)
    }

    private func makeTimeToSampleBox(entries: [TimeToSampleEntryParameters]) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)
        for entry in entries {
            payload.append(contentsOf: entry.sampleCount.bigEndianBytes)
            payload.append(contentsOf: entry.sampleDelta.bigEndianBytes)
        }
        return makeBox(type: "stts", payload: payload)
    }

    private func makeCompositionOffsetBox(
        version: UInt8 = 0,
        entries: [CompositionOffsetEntryParameters]
    ) -> Data {
        var payload = Data()
        payload.append(version)
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)
        for entry in entries {
            payload.append(contentsOf: entry.sampleCount.bigEndianBytes)
            if version == 0 {
                precondition(entry.sampleOffset >= 0, "Version 0 offsets must be non-negative")
                payload.append(contentsOf: UInt32(entry.sampleOffset).bigEndianBytes)
            } else {
                payload.append(contentsOf: entry.sampleOffset.bigEndianBytes)
            }
        }
        return makeBox(type: "ctts", payload: payload)
    }

    private func makeSampleSizeBox(
        defaultSampleSize: UInt32,
        sampleCount: UInt32,
        explicitSizes: [UInt32] = []
    ) -> Data {
        if defaultSampleSize == 0 {
            precondition(explicitSizes.count == Int(sampleCount), "Explicit sample sizes must match sampleCount when default size is zero")
        } else {
            precondition(explicitSizes.isEmpty, "Explicit sample sizes are only supported when default size is zero")
        }

        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: defaultSampleSize.bigEndianBytes)
        payload.append(contentsOf: sampleCount.bigEndianBytes)
        if defaultSampleSize == 0 {
            explicitSizes.forEach { payload.append(contentsOf: $0.bigEndianBytes) }
        }
        return makeBox(type: "stsz", payload: payload)
    }

    private func makeChunkOffsetBox(offsets: [UInt64]) -> Data {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(offsets.count).bigEndianBytes)
        for offset in offsets {
            precondition(offset <= UInt64(UInt32.max), "Chunk offset exceeds 32-bit range")
            payload.append(contentsOf: UInt32(offset).bigEndianBytes)
        }
        return makeBox(type: "stco", payload: payload)
    }

    private func makeMetadataItemEntry(identifierBytes: [UInt8], dataBox: Data) -> Data {
        precondition(identifierBytes.count == 4)
        var entry = Data()
        entry.append(contentsOf: UInt32(8 + dataBox.count).bigEndianBytes)
        entry.append(contentsOf: identifierBytes)
        entry.append(dataBox)
        return entry
    }

    private func makeMetadataDataBox(type: UInt32, locale: UInt32, data: Data) -> Data {
        var box = Data()
        box.append(contentsOf: UInt32(16 + data.count).bigEndianBytes)
        box.append(contentsOf: "data".utf8)
        box.append(0x00) // version
        box.append(UInt8((type >> 16) & 0xFF))
        box.append(UInt8((type >> 8) & 0xFF))
        box.append(UInt8(type & 0xFF))
        box.append(contentsOf: locale.bigEndianBytes)
        box.append(data)
        return box
    }

    private struct TrackFragmentRandomAccessEntryParameters {
        let time: UInt64
        let moofOffset: UInt64
        let trafNumber: UInt64
        let trunNumber: UInt64
        let sampleNumber: UInt64
    }

    private func makeTrackFragmentRandomAccessBox(
        version: UInt8,
        trackID: UInt32,
        entries: [TrackFragmentRandomAccessEntryParameters]
    ) -> Data {
        precondition(version == 0 || version == 1, "Unsupported tfra version for test fixture")
        var payload = Data()
        payload.append(version)
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: trackID.bigEndianBytes)

        let lengthIndicator: UInt32 = (0b11 << 4) | (0b11 << 2) | 0b11
        payload.append(contentsOf: lengthIndicator.bigEndianBytes)
        payload.append(contentsOf: UInt32(entries.count).bigEndianBytes)

        for entry in entries {
            if version == 1 {
                payload.append(contentsOf: entry.time.bigEndianBytes)
                payload.append(contentsOf: entry.moofOffset.bigEndianBytes)
            } else {
                payload.append(contentsOf: UInt32(truncatingIfNeeded: entry.time).bigEndianBytes)
                payload.append(contentsOf: UInt32(truncatingIfNeeded: entry.moofOffset).bigEndianBytes)
            }
            payload.append(contentsOf: UInt32(truncatingIfNeeded: entry.trafNumber).bigEndianBytes)
            payload.append(contentsOf: UInt32(truncatingIfNeeded: entry.trunNumber).bigEndianBytes)
            payload.append(contentsOf: UInt32(truncatingIfNeeded: entry.sampleNumber).bigEndianBytes)
        }

        return makeBox(type: "tfra", payload: payload)
    }

    private func makeMovieFragmentRandomAccessBox(trackEntries: [Data]) -> Data {
        var payload = Data()
        for table in trackEntries {
            payload.append(table)
        }

        let mfroSize = 16
        let totalMfraSize = UInt32(8 + payload.count + mfroSize)

        var mfroPayload = Data()
        mfroPayload.append(0x00)
        mfroPayload.append(contentsOf: [0x00, 0x00, 0x00])
        mfroPayload.append(contentsOf: totalMfraSize.bigEndianBytes)
        let mfro = makeBox(type: "mfro", payload: mfroPayload)

        payload.append(mfro)
        return makeBox(type: "mfra", payload: payload)
    }
}

private enum ContainerTypes {
    static let movie = FourCharContainerCode.moov.rawValue
    static let track = FourCharContainerCode.trak.rawValue
    static let media = FourCharContainerCode.mdia.rawValue
    static let movieFragment = FourCharContainerCode.moof.rawValue
    static let trackFragment = FourCharContainerCode.traf.rawValue
}

private func languageBytes(_ code: String) -> [UInt8] {
    precondition(code.count == 3, "language code must be 3 letters")
    let scalars = code.unicodeScalars.map { UInt16($0.value) - 0x60 }
    let packed = UInt16(((scalars[0] & 0x1F) << 10) | ((scalars[1] & 0x1F) << 5) | (scalars[2] & 0x1F))
    return packed.bigEndianBytes
}

private extension FixedWidthInteger {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian, Array.init)
    }
}

private extension UInt32 {
    var bigEndianFlagBytes: [UInt8] {
        [
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}
