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
        let type = try FourCharCode(expectedType)
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
}

private enum ContainerTypes {
    static let movie = FourCharContainerCode.moov.rawValue
    static let track = FourCharContainerCode.trak.rawValue
    static let media = FourCharContainerCode.mdia.rawValue
    static let movieFragment = FourCharContainerCode.moof.rawValue
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
