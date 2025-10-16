import _Concurrency
import Foundation
import XCTest

private final class LockedValueBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func withValue<T>(_ update: (inout Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return update(&value)
    }
}
@testable import ISOInspectorApp
@testable import ISOInspectorCLI
@testable import ISOInspectorKit
#if canImport(Combine)
import Combine
#endif

final class LargeFileBenchmarkTests: XCTestCase {
    private lazy var configuration = PerformanceBenchmarkConfiguration()

    func testCLIValidationCompletesWithinPerformanceBudget() throws {
        let fixture = try LargeFileBenchmarkFixture.make(configuration: configuration)
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { url in try ChunkedFileReader(fileURL: url) },
            parsePipeline: .live(),
            formatter: EventConsoleFormatter(),
            print: { _ in },
            printError: { _ in }
        )

        performBenchmark(iterations: configuration.iterationCount) {
            let start = Date()
            try runValidateCommand(on: fixture.url, environment: environment)
            let duration = Date().timeIntervalSince(start)
            XCTAssertLessThanOrEqual(
                duration,
                configuration.cliDurationBudgetSeconds(),
                "CLI validation exceeded budget for payload of \(configuration.payloadBytes) bytes"
            )

            let eventCount = try drainEvents(
                using: environment.parsePipeline,
                fileURL: fixture.url
            )
            XCTAssertEqual(eventCount, fixture.expectedEventCount)
        }
    }

    #if canImport(Combine)
    func testAppEventBridgeDeliversUpdatesWithinLatencyBudget() throws {
        let fixture = try LargeFileBenchmarkFixture.make(configuration: configuration)

        performBenchmark(iterations: configuration.iterationCount) {
            let pipeline = ParsePipeline.live()
            let reader = try ChunkedFileReader(fileURL: fixture.url)
            let bridge = ParsePipelineEventBridge()
            let connection = bridge.makeConnection(
                pipeline: pipeline,
                reader: reader
            )
            let expectation = expectation(description: "Stream completed")
            var cancellable: AnyCancellable?
            var eventCount = 0
            var firstEventLatency: TimeInterval?
            let start = Date()

            cancellable = connection.events.sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Stream failed with error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    eventCount += 1
                    if firstEventLatency == nil {
                        firstEventLatency = Date().timeIntervalSince(start)
                    }
                }
            )

            wait(for: [expectation], timeout: configuration.cliDurationBudgetSeconds() * 2)
            cancellable?.cancel()
            connection.cancel()

            XCTAssertEqual(eventCount, fixture.expectedEventCount)
            if let latency = firstEventLatency {
                XCTAssertLessThanOrEqual(
                    latency,
                    configuration.uiLatencyBudgetSeconds(),
                    "First UI update latency exceeded budget"
                )
            } else {
                XCTFail("No events received during UI benchmark")
            }
        }
    }
    #else
    func testAppEventBridgeDeliversUpdatesWithinLatencyBudget() throws {
        throw XCTSkip("Combine unavailable on this platform")
    }
    #endif

    func testMappedReaderRandomSliceBenchmarkMeetsPerformanceExpectations() throws {
        let fixture = try LargeFileBenchmarkFixture.make(configuration: configuration)
        try runRandomSliceBenchmark(
            readerName: "MappedReader",
            fixture: fixture,
            makeReader: { url in try MappedReader(fileURL: url) }
        )
    }

    func testChunkedFileReaderRandomSliceBenchmarkMeetsPerformanceExpectations() throws {
        let fixture = try LargeFileBenchmarkFixture.make(configuration: configuration)
        try runRandomSliceBenchmark(
            readerName: "ChunkedFileReader",
            fixture: fixture,
            makeReader: { url in try ChunkedFileReader(fileURL: url) }
        )
    }
}

private extension LargeFileBenchmarkTests {
    func performBenchmark(iterations: Int, block: () throws -> Void) {
        #if canImport(ObjectiveC)
        if #available(macOS 13.0, iOS 16.0, *) {
            let metrics: [XCTMetric] = [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]
            let options = XCTMeasureOptions()
            options.iterationCount = iterations
            measure(metrics: metrics, options: options) {
                do {
                    try block()
                } catch {
                    XCTFail("Benchmark iteration failed: \(error)")
                }
            }
            return
        }
        #endif

        for _ in 0..<iterations {
            do {
                try block()
            } catch {
                XCTFail("Benchmark iteration failed: \(error)")
            }
        }
    }

    func runRandomSliceBenchmark(
        readerName: String,
        fixture: LargeFileBenchmarkFixture,
        makeReader: (URL) throws -> any RandomAccessReader
    ) throws {
        let scenarios = RandomSliceBenchmarkScenario.makeDefaultScenarios(payloadBytes: configuration.payloadBytes)

        for scenario in scenarios {
            let reader = try makeReader(fixture.url)
            let requests = scenario.makeRequests(fileLength: reader.length)
            let expectedBytes = requests.reduce(into: 0) { $0 += $1.count }
            XCTAssertFalse(requests.isEmpty, "Scenario \(scenario.name) produced no slice requests for \(readerName)")

            performBenchmark(iterations: configuration.iterationCount) {
                let bytesRead = try executeRandomSliceRequests(
                    requests,
                    using: reader,
                    readerName: readerName,
                    scenarioName: scenario.name
                )
                XCTAssertEqual(
                    bytesRead,
                    expectedBytes,
                    "Reader \(readerName) returned truncated data while benchmarking scenario \(scenario.name)"
                )
            }

            let summary = scenario.makeSummary(
                readerName: readerName,
                totalBytesPerIteration: expectedBytes,
                requestCount: requests.count,
                readerLength: reader.length
            )
            print(summary)
        }
    }

    func executeRandomSliceRequests(
        _ requests: [RandomSliceRequest],
        using reader: any RandomAccessReader,
        readerName: String,
        scenarioName: String
    ) throws -> Int {
        var totalBytes = 0
        for request in requests {
            do {
                let data = try reader.read(at: request.offset, count: request.count)
                XCTAssertEqual(
                    data.count,
                    request.count,
                    "Reader \(readerName) truncated slice during scenario \(scenarioName) (offset: \(request.offset), count: \(request.count))"
                )
                totalBytes += data.count
            } catch {
                let prefix = "Reader \(readerName) failed random slice scenario \(scenarioName) (offset: \(request.offset), count: \(request.count))"
                if let readerError = error as? RandomAccessReaderError {
                    XCTFail("\(prefix): \(readerError)")
                } else {
                    XCTFail("\(prefix): unexpected error type \(error)")
                }
                throw error
            }
        }
        return totalBytes
    }

    func runValidateCommand(
        on fileURL: URL,
        environment: ISOInspectorCLIEnvironment
    ) throws {
        let expectation = expectation(description: "validate command completed")
        let capturedError = LockedValueBox<Error?>(nil)

        Task {
            await MainActor.run {
                ISOInspectorCommandContextStore.bootstrap(with: ISOInspectorCommandContext(environment: environment))
            }
            var command = ISOInspectorCommand.Commands.Validate()
            command.file = fileURL.path
            do {
                try await command.run()
            } catch {
                capturedError.withValue { $0 = error }
            }
            await MainActor.run {
                ISOInspectorCommandContextStore.reset()
            }
            expectation.fulfill()
        }

        wait(
            for: [expectation],
            timeout: max(configuration.cliDurationBudgetSeconds() * 4, 1)
        )

        if let error = capturedError.withValue({ $0 }) {
            throw error
        }
    }
}

private func drainEvents(
    using pipeline: ParsePipeline,
    fileURL: URL
) throws -> Int {
    let reader = try ChunkedFileReader(fileURL: fileURL)
    let stream = pipeline.events(for: reader)
    let semaphore = DispatchSemaphore(value: 0)
    let count = LockedValueBox(0)
    let capturedError = LockedValueBox<Error?>(nil)

    Task {
        do {
            for try await _ in stream {
                count.withValue { $0 += 1 }
            }
        } catch {
            capturedError.withValue { $0 = error }
        }
        semaphore.signal()
    }

    semaphore.wait()
    if let error = capturedError.withValue({ $0 }) {
        throw error
    }
    return count.withValue { $0 }
}

private struct LargeFileBenchmarkFixture {
    let url: URL
    let expectedEventCount: Int

    static func make(
        configuration: PerformanceBenchmarkConfiguration,
        fileManager: FileManager = .default
    ) throws -> LargeFileBenchmarkFixture {
        let payloadBytes = configuration.payloadBytes
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("isoinspector-benchmarks", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("large-\(payloadBytes).mp4")
        let expectedSize = LargeFileBenchmarkFixtureBuilder.expectedFileSize(payloadBytes: payloadBytes)
        if fileManager.fileExists(atPath: url.path) {
            if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attributes[FileAttributeKey.size] as? NSNumber,
               size.intValue == expectedSize {
                return LargeFileBenchmarkFixture(url: url, expectedEventCount: 8)
            }
            try fileManager.removeItem(at: url)
        }

        let builder = LargeFileBenchmarkFixtureBuilder(payloadBytes: payloadBytes)
        try builder.write(to: url)
        return LargeFileBenchmarkFixture(url: url, expectedEventCount: 8)
    }
}

private struct LargeFileBenchmarkFixtureBuilder {
    let payloadBytes: Int

    static func expectedFileSize(payloadBytes: Int) -> Int {
        let ftypSize = 8 + 16
        let mvhdPayloadSize = 4 + 96
        let mvhdSize = 8 + mvhdPayloadSize
        let moovSize = 8 + mvhdSize
        let mdatHeaderSize = 16
        return ftypSize + moovSize + mdatHeaderSize + payloadBytes
    }

    func write(to url: URL) throws {
        var header = Data()
        header.append(makeBox(type: "ftyp", payload: makeBrandPayload()))
        header.append(makeBox(type: "moov", payload: makeMovieHeaderBox()))
        header.append(makeLargeBoxHeader(type: "mdat", payloadSize: payloadBytes))
        try header.write(to: url, options: .atomic)
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        let chunkSize = min(1_048_576, max(payloadBytes, 1))
        let chunk = Data(repeating: 0x55, count: chunkSize)
        var remaining = payloadBytes
        while remaining > 0 {
            let portion = min(remaining, chunk.count)
            try handle.write(contentsOf: chunk.prefix(portion))
            remaining -= portion
        }
        try handle.close()
    }

    private func makeBrandPayload() -> Data {
        var data = Data()
        data.append(contentsOf: "isom".utf8)
        appendUInt32(0x00000200, to: &data)
        data.append(contentsOf: "isom".utf8)
        data.append(contentsOf: "iso2".utf8)
        return data
    }

    private func makeMovieHeaderBox() -> Data {
        var payload = Data()
        payload.append(Data([0, 0, 0, 0]))
        payload.append(Data(repeating: 0, count: 96))
        return makeBox(type: "mvhd", payload: payload)
    }

    private func makeBox(type: String, payload: Data) -> Data {
        precondition(type.count == 4, "Box type must be four characters")
        var box = Data()
        let size = UInt32(8 + payload.count)
        appendUInt32(size, to: &box)
        box.append(contentsOf: type.utf8)
        box.append(payload)
        return box
    }

    private func makeLargeBoxHeader(type: String, payloadSize: Int) -> Data {
        precondition(type.count == 4, "Box type must be four characters")
        var box = Data()
        appendUInt32(1, to: &box)
        box.append(contentsOf: type.utf8)
        appendUInt64(UInt64(16 + payloadSize), to: &box)
        return box
    }
}

private struct RandomSliceRequest: Sendable {
    let offset: Int64
    let count: Int
}

private struct RandomSliceBenchmarkScenario: Sendable {
    let name: String
    let minimumBytes: Int
    let maximumBytes: Int
    let sampleCount: Int
    let seed: UInt64

    static func makeDefaultScenarios(payloadBytes: Int) -> [RandomSliceBenchmarkScenario] {
        let cappedPayload = max(payloadBytes, 1)
        let mediumUpper = min(max(cappedPayload / 256, 8_192), 131_072)
        let largeUpper = min(max(cappedPayload / 32, 131_072), 1_048_576)

        return [
            RandomSliceBenchmarkScenario(
                name: "small",
                minimumBytes: 32,
                maximumBytes: 512,
                sampleCount: 256,
                seed: 0xA5A5_0001
            ),
            RandomSliceBenchmarkScenario(
                name: "medium",
                minimumBytes: 4_096,
                maximumBytes: mediumUpper,
                sampleCount: 128,
                seed: 0xA5A5_0002
            ),
            RandomSliceBenchmarkScenario(
                name: "large",
                minimumBytes: 65_536,
                maximumBytes: largeUpper,
                sampleCount: 64,
                seed: 0xA5A5_0003
            )
        ]
    }

    func makeRequests(fileLength: Int64) -> [RandomSliceRequest] {
        guard fileLength > 0 else { return [] }

        let cappedLength = max(Int(clamping: fileLength), 1)

        let effectiveMax = min(maximumBytes, cappedLength)
        let effectiveMin = max(1, min(minimumBytes, effectiveMax))
        guard effectiveMin <= effectiveMax else { return [] }

        var generator = SplitMix64(seed: seed)
        var requests: [RandomSliceRequest] = []
        requests.reserveCapacity(sampleCount)

        for _ in 0..<sampleCount {
            let count = Int.random(in: effectiveMin...effectiveMax, using: &generator)
            let maxOffset = max(0, cappedLength - count)
            let offset: Int64
            if maxOffset > 0 {
                let offsetValue = Int.random(in: 0...maxOffset, using: &generator)
                offset = Int64(offsetValue)
            } else {
                offset = 0
            }
            requests.append(RandomSliceRequest(offset: offset, count: count))
        }

        return requests
    }

    func makeSummary(
        readerName: String,
        totalBytesPerIteration: Int,
        requestCount: Int,
        readerLength: Int64
    ) -> String {
        let locale = Locale(identifier: "en_US_POSIX")
        let average = requestCount > 0 ? Double(totalBytesPerIteration) / Double(requestCount) : 0
        let bytesMiB = Double(totalBytesPerIteration) / 1_048_576.0
        let readerMiB = Double(readerLength) / 1_048_576.0

        let averageString = String(format: "%.2f", locale: locale, average)
        let bytesString = String(format: "%.2f", locale: locale, bytesMiB)
        let lengthString = String(format: "%.2f", locale: locale, readerMiB)

        return """
        \(readerName) random slice scenario: \(name)
        • Requests per iteration: \(requestCount)
        • Total bytes per iteration: \(totalBytesPerIteration) (\(bytesString) MiB)
        • Average slice size: \(averageString) bytes
        • Reader length: \(readerLength) (\(lengthString) MiB)
        """
    }
}

private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private func appendUInt32(_ value: UInt32, to data: inout Data) {
    data.append(UInt8((value >> 24) & 0xFF))
    data.append(UInt8((value >> 16) & 0xFF))
    data.append(UInt8((value >> 8) & 0xFF))
    data.append(UInt8(value & 0xFF))
}

private func appendUInt64(_ value: UInt64, to data: inout Data) {
    data.append(UInt8((value >> 56) & 0xFF))
    data.append(UInt8((value >> 48) & 0xFF))
    data.append(UInt8((value >> 40) & 0xFF))
    data.append(UInt8((value >> 32) & 0xFF))
    data.append(UInt8((value >> 24) & 0xFF))
    data.append(UInt8((value >> 16) & 0xFF))
    data.append(UInt8((value >> 8) & 0xFF))
    data.append(UInt8(value & 0xFF))
}
