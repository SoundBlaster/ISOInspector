import Foundation
import XCTest

@testable import ISOInspectorCLI
@testable import ISOInspectorKit

final class JSONExportCompatibilityCLITests: XCTestCase {
    func testExportedJSONMatchesCompatibilityBaselines() throws {
        let root = repositoryRoot()
        let fixtureURL = root.appendingPathComponent("DOCS", isDirectory: true)
            .appendingPathComponent("SAMPLES", isDirectory: true).appendingPathComponent(
                "Bento4-master", isDirectory: true
            ).appendingPathComponent("Test", isDirectory: true).appendingPathComponent(
                "Data", isDirectory: true
            ).appendingPathComponent("video-h264-001.mp4", isDirectory: false)
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: fixtureURL.path),
            "Fixture not found at \(fixtureURL.path)")

        let workDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(
            at: workDirectory, withIntermediateDirectories: true)
        let outputURL = workDirectory.appendingPathComponent("export.json")

        let ffprobeFormat = try loadFFProbeBaseline(from: root)
        let ffprobeTags = try XCTUnwrap(ffprobeFormat["tags"] as? [String: Any])
        let compatibleBrandString = ffprobeTags["compatible_brands"] as? String ?? ""
        let compatibleBrands = try Self.splitFourCCString(compatibleBrandString)
        let bentoBaseline = try loadBento4Baseline(from: root)
        let parseTreeNodes = try makeParseTreeNodes(
            from: bentoBaseline, compatibleBrands: compatibleBrands)
        let pipelineEvents = makeEvents(from: parseTreeNodes)

        let printed = MutableBox<[String]>([])
        let errors = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in }, makeReader: { _ in StubReader() },
            parsePipeline: ParsePipeline(buildStream: { _, _ in
                var iterator = pipelineEvents.makeIterator()
                return AsyncThrowingStream { continuation in
                    while let event = iterator.next() { continuation.yield(event) }
                    continuation.finish()
                }
            }), formatter: EventConsoleFormatter(), print: { printed.append($0) },
            printError: { errors.append($0) })

        ISOInspectorCLIRunner.run(
            arguments: ["isoinspect", "export-json", fixtureURL.path, "--output", outputURL.path],
            environment: environment)

        XCTAssertTrue(errors.value.isEmpty, "CLI reported errors: \(errors.value)")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        let exportData = try Data(contentsOf: outputURL)
        let exportObject = try JSONSerialization.jsonObject(with: exportData, options: [])
        let exportJSON = try XCTUnwrap(
            exportObject as? [String: Any], "Export root should be a dictionary")

        try assertCompatibilityAliases(
            exportNodes: try XCTUnwrap(
                exportJSON["nodes"] as? [[String: Any]], "Export nodes missing"),
            bentoBaseline: bentoBaseline)

        try assertFormatSummary(
            exportFormat: try XCTUnwrap(
                exportJSON["format"] as? [String: Any], "Format summary missing"),
            ffprobeBaseline: ffprobeFormat)

        try assertIssueMetrics(
            exportJSON: exportJSON,
            exportNodes: try XCTUnwrap(
                exportJSON["nodes"] as? [[String: Any]], "Nodes missing from export"))
    }

    private func assertCompatibilityAliases(
        exportNodes: [[String: Any]], bentoBaseline: [[String: Any]]
    ) throws {
        let exportAliases = flattenKitNodes(exportNodes)
        let bentoAliases = flattenBentoNodes(bentoBaseline)

        XCTAssertEqual(
            exportAliases.count, bentoAliases.count, "Compatibility alias count mismatch")

        for (index, pair) in zip(exportAliases, bentoAliases).enumerated() {
            let (exportAlias, baselineAlias) = pair
            XCTAssertEqual(exportAlias.name, baselineAlias.name, "Name mismatch at index \(index)")
            XCTAssertEqual(
                exportAlias.headerSize, baselineAlias.headerSize,
                "header_size mismatch for \(baselineAlias.name) at index \(index)")
            XCTAssertEqual(
                exportAlias.size, baselineAlias.size,
                "size mismatch for \(baselineAlias.name) at index \(index)")
        }
    }

    private func assertFormatSummary(exportFormat: [String: Any], ffprobeBaseline: [String: Any])
        throws
    {
        let tags = try XCTUnwrap(ffprobeBaseline["tags"] as? [String: Any])

        XCTAssertEqual(exportFormat["major_brand"] as? String, tags["major_brand"] as? String)

        let exportMinor = Self.intValue(forKey: "minor_version", in: exportFormat)
        let baselineMinor = try Self.parseInt(from: tags["minor_version"])
        XCTAssertEqual(exportMinor, baselineMinor)

        let exportBrands = try XCTUnwrap(exportFormat["compatible_brands"] as? [String])
        let baselineBrands = try Self.splitFourCCString(
            try XCTUnwrap(tags["compatible_brands"] as? String))
        XCTAssertEqual(exportBrands, baselineBrands)

        let exportDuration = try XCTUnwrap(exportFormat["duration_seconds"] as? Double)
        let baselineDuration = try Self.parseDouble(from: ffprobeBaseline["duration"])
        XCTAssertEqual(exportDuration, baselineDuration, accuracy: 0.01)

        let exportSize = Self.intValue(forKey: "byte_size", in: exportFormat)
        let baselineSize = try Self.parseInt(from: ffprobeBaseline["size"])
        XCTAssertEqual(exportSize, baselineSize)

        let exportBitrate = Self.intValue(forKey: "bitrate", in: exportFormat)
        let baselineBitrate = try Self.parseInt(from: ffprobeBaseline["bit_rate"])
        XCTAssertLessThanOrEqual(abs(exportBitrate - baselineBitrate), 32)

        let exportTracks = Self.intValue(forKey: "track_count", in: exportFormat)
        let baselineStreams = try Self.parseInt(from: ffprobeBaseline["nb_streams"])
        XCTAssertEqual(exportTracks, baselineStreams)
    }

    private func loadBento4Baseline(from root: URL) throws -> [[String: Any]] {
        let url = root.appendingPathComponent("DOCS", isDirectory: true).appendingPathComponent(
            "TASK_ARCHIVE", isDirectory: true
        ).appendingPathComponent("151_R5_Export_Schema_Standardization", isDirectory: true)
            .appendingPathComponent("R5_mp4dump_video-h264-001.json", isDirectory: false)
        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        return try XCTUnwrap(object as? [[String: Any]], "Bento4 baseline must be an array")
    }

    private func loadFFProbeBaseline(from root: URL) throws -> [String: Any] {
        let url = root.appendingPathComponent("DOCS", isDirectory: true).appendingPathComponent(
            "TASK_ARCHIVE", isDirectory: true
        ).appendingPathComponent("151_R5_Export_Schema_Standardization", isDirectory: true)
            .appendingPathComponent("R5_ffprobe_video-h264-001.json", isDirectory: false)
        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        let rootObject = try XCTUnwrap(
            object as? [String: Any], "ffprobe baseline must be a dictionary")
        return try XCTUnwrap(
            rootObject["format"] as? [String: Any], "ffprobe format section missing")
    }

    private func makeParseTreeNodes(from baseline: [[String: Any]], compatibleBrands: [String])
        throws -> [ParseTreeNode]
    {
        var offset: Int64 = 0
        return try buildNodes(baseline, compatibleBrands: compatibleBrands, currentOffset: &offset)
    }

    private func buildNodes(
        _ nodes: [[String: Any]], compatibleBrands: [String], currentOffset: inout Int64
    ) throws -> [ParseTreeNode] {
        var result: [ParseTreeNode] = []
        for dictionary in nodes {
            guard let name = dictionary["name"] as? String, name.count == 4 else { continue }
            let headerSize = Self.intValue(forKey: "header_size", in: dictionary)
            let totalSize = Self.intValue(forKey: "size", in: dictionary)
            let start = currentOffset
            let end = start + Int64(totalSize)
            let payloadStart = start + Int64(headerSize)
            let payloadEnd = end
            var childOffset = payloadStart
            let children = try buildNodes(
                dictionary["children"] as? [[String: Any]] ?? [],
                compatibleBrands: compatibleBrands, currentOffset: &childOffset)
            currentOffset = end

            let type = try FourCharCode(name)
            let header = BoxHeader(
                type: type, totalSize: Int64(totalSize), headerSize: Int64(headerSize),
                payloadRange: payloadStart..<payloadEnd, range: start..<end, uuid: nil)
            let payload = makePayload(
                name: name, dictionary: dictionary, compatibleBrands: compatibleBrands)
            result.append(
                ParseTreeNode(
                    header: header, metadata: nil, payload: payload, validationIssues: [],
                    children: children))
        }
        return result
    }

    private func makePayload(name: String, dictionary: [String: Any], compatibleBrands: [String])
        -> ParsedBoxPayload?
    {
        switch name {
        case "ftyp":
            guard let major = dictionary["major_brand"] as? String,
                let majorCode = try? ISOInspectorKit.FourCharCode(major)
            else { return nil }
            let minor = UInt32(Self.intValue(forKey: "minor_version", in: dictionary))
            let brandCodes: [ISOInspectorKit.FourCharCode] = compatibleBrands.compactMap {
                try? ISOInspectorKit.FourCharCode($0)
            }
            let detail = ParsedBoxPayload.FileTypeBox(
                majorBrand: majorCode, minorVersion: minor, compatibleBrands: brandCodes)
            return ParsedBoxPayload(fields: [], detail: .fileType(detail))
        case "mvhd":
            let timescale = UInt32(Self.intValue(forKey: "timescale", in: dictionary))
            let duration = UInt64(Self.intValue(forKey: "duration", in: dictionary))
            let detail = ParsedBoxPayload.MovieHeaderBox(
                version: 0, creationTime: 0, modificationTime: 0, timescale: timescale,
                duration: duration, durationIs64Bit: false, rate: 1.0, volume: 1.0,
                matrix: ParsedBoxPayload.TransformationMatrix.identity, nextTrackID: 0)
            return ParsedBoxPayload(fields: [], detail: .movieHeader(detail))
        default: return nil
        }
    }

    private func makeEvents(from nodes: [ParseTreeNode]) -> [ParseEvent] {
        var events: [ParseEvent] = []
        func walk(_ node: ParseTreeNode, depth: Int) {
            events.append(
                ParseEvent(
                    kind: .willStartBox(header: node.header, depth: depth),
                    offset: node.header.startOffset, metadata: node.metadata, payload: node.payload)
            )
            for child in node.children { walk(child, depth: depth + 1) }
            events.append(
                ParseEvent(
                    kind: .didFinishBox(header: node.header, depth: depth),
                    offset: node.header.endOffset, metadata: node.metadata, payload: node.payload))
        }
        for node in nodes { walk(node, depth: 0) }
        return events
    }

    private func flattenKitNodes(_ nodes: [[String: Any]]) -> [Alias] {
        var result: [Alias] = []
        for node in nodes {
            let name = node["name"] as? String ?? ""
            let header = Self.intValue(forKey: "header_size", in: node)
            let size = Self.intValue(forKey: "size", in: node)
            result.append(Alias(name: name, headerSize: header, size: size))
            if let children = node["children"] as? [[String: Any]] {
                result.append(contentsOf: flattenKitNodes(children))
            }
        }
        return result
    }

    private func flattenBentoNodes(_ nodes: [[String: Any]]) -> [Alias] {
        var result: [Alias] = []
        for node in nodes {
            guard let name = node["name"] as? String, name.count == 4 else {
                if let children = node["children"] as? [[String: Any]] {
                    result.append(contentsOf: flattenBentoNodes(children))
                }
                continue
            }
            let header = Self.intValue(forKey: "header_size", in: node)
            let size = Self.intValue(forKey: "size", in: node)
            result.append(Alias(name: name, headerSize: header, size: size))
            if let children = node["children"] as? [[String: Any]] {
                result.append(contentsOf: flattenBentoNodes(children))
            }
        }
        return result
    }

    private func assertIssueMetrics(exportJSON: [String: Any], exportNodes: [[String: Any]]) throws
    {
        let metrics = try XCTUnwrap(
            exportJSON["issue_metrics"] as? [String: Any], "Issue metrics missing from export")
        let expected = computeIssueMetrics(from: exportNodes)

        XCTAssertEqual(
            Self.intValue(forKey: "error_count", in: metrics), expected.errorCount,
            "Error count mismatch")
        XCTAssertEqual(
            Self.intValue(forKey: "warning_count", in: metrics), expected.warningCount,
            "Warning count mismatch")
        XCTAssertEqual(
            Self.intValue(forKey: "info_count", in: metrics), expected.infoCount,
            "Info count mismatch")
        XCTAssertEqual(
            Self.intValue(forKey: "deepest_affected_depth", in: metrics),
            expected.deepestAffectedDepth, "Deepest affected depth mismatch")
    }

    private func computeIssueMetrics(from nodes: [[String: Any]]) -> IssueMetrics {
        var metrics = IssueMetrics()
        accumulateIssues(in: nodes, depth: 0, metrics: &metrics)
        return metrics
    }

    private func accumulateIssues(
        in nodes: [[String: Any]], depth: Int, metrics: inout IssueMetrics
    ) {
        for node in nodes {
            if let issues = node["issues"] as? [[String: Any]], !issues.isEmpty {
                for issue in issues {
                    let identifier = IssueIdentifier(issue: issue)
                    let previousDepth = metrics.trackedIssues[identifier]
                    if previousDepth == nil {
                        switch issue["severity"] as? String {
                        case "error": metrics.errorCount += 1
                        case "warning": metrics.warningCount += 1
                        case "info": metrics.infoCount += 1
                        default: break
                        }
                    }
                    let resolvedDepth = max(previousDepth ?? depth, depth)
                    metrics.trackedIssues[identifier] = resolvedDepth
                    metrics.deepestAffectedDepth = max(metrics.deepestAffectedDepth, resolvedDepth)
                }
            }
            if let children = node["children"] as? [[String: Any]] {
                accumulateIssues(in: children, depth: depth + 1, metrics: &metrics)
            }
        }
    }

    private func repositoryRoot() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "ISOInspector", url.pathComponents.count > 1 {
            url.deleteLastPathComponent()
        }
        return url
    }

    private static func intValue(forKey key: String, in dictionary: [String: Any]?) -> Int {
        guard let value = dictionary?[key] else { return 0 }
        if let intValue = value as? Int { return intValue }
        if let number = value as? NSNumber { return number.intValue }
        return 0
    }

    private static func parseInt(from value: Any?) throws -> Int {
        if let intValue = value as? Int { return intValue }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String, let parsed = Int(string) { return parsed }
        XCTFail("Unable to parse integer from \(String(describing: value))")
        throw NSError(domain: "JSONExportCompatibilityCLITests", code: 1)
    }

    private static func parseDouble(from value: Any?) throws -> Double {
        if let doubleValue = value as? Double { return doubleValue }
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? String, let parsed = Double(string) { return parsed }
        XCTFail("Unable to parse double from \(String(describing: value))")
        throw NSError(domain: "JSONExportCompatibilityCLITests", code: 2)
    }

    private static func splitFourCCString(_ value: String) throws -> [String] {
        guard value.count % 4 == 0 else {
            XCTFail("Expected concatenated fourcc string but received \(value)")
            throw NSError(domain: "JSONExportCompatibilityCLITests", code: 3)
        }
        var result: [String] = []
        var index = value.startIndex
        while index < value.endIndex {
            let nextIndex = value.index(index, offsetBy: 4)
            result.append(String(value[index..<nextIndex]))
            index = nextIndex
        }
        return result
    }

    private struct Alias: Equatable {
        let name: String
        let headerSize: Int
        let size: Int
    }

    private struct IssueMetrics {
        var errorCount: Int = 0
        var warningCount: Int = 0
        var infoCount: Int = 0
        var deepestAffectedDepth: Int = 0
        var trackedIssues: [IssueIdentifier: Int] = [:]
    }

    private struct IssueIdentifier: Hashable {
        let severity: String?
        let code: String?
        let message: String?
        let byteRangeLowerBound: Int64?
        let byteRangeUpperBound: Int64?
        let affectedNodeIDs: [Int64]

        init(issue: [String: Any]) {
            severity = issue["severity"] as? String
            code = issue["code"] as? String
            message = issue["message"] as? String
            if let range = issue["byte_range"] as? [String: Any] {
                byteRangeLowerBound = Self.int64Value(forKey: "start", in: range)
                byteRangeUpperBound = Self.int64Value(forKey: "end", in: range)
            } else {
                byteRangeLowerBound = nil
                byteRangeUpperBound = nil
            }
            if let nodeIDs = issue["affected_node_ids"] as? [Int64] {
                affectedNodeIDs = nodeIDs
            } else if let nodeIDs = issue["affected_node_ids"] as? [NSNumber] {
                affectedNodeIDs = nodeIDs.map { $0.int64Value }
            } else {
                affectedNodeIDs = []
            }
        }

        private static func int64Value(forKey key: String, in dictionary: [String: Any]) -> Int64? {
            if let value = dictionary[key] as? NSNumber { return value.int64Value }
            if let value = dictionary[key] as? Int64 { return value }
            if let value = dictionary[key] as? Int { return Int64(value) }
            return nil
        }
    }
}

private final class MutableBox<Value>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSLock()

    init(_ value: Value) { self._value = value }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func append(_ element: Value.Element) where Value: RangeReplaceableCollection {
        lock.lock()
        _value.append(element)
        lock.unlock()
    }
}

private struct StubReader: RandomAccessReader {
    func read(at offset: Int64, count: Int) throws -> Data { Data(count: count) }

    func read<T>(at offset: Int64, into buffer: UnsafeMutableBufferPointer<T>) throws
    where T: FixedWidthInteger { buffer.initialize(repeating: 0) }

    var length: Int64 { 0 }
}
