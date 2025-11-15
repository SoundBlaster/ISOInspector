import Foundation
import XCTest
import _Concurrency

@testable import ISOInspectorApp
@testable import ISOInspectorCLI
@testable import ISOInspectorKit

#if os(Linux)
  import Glibc
#else
  import Darwin
  import Darwin.Mach
#endif

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
#if canImport(Combine)
  import Combine
#endif

final class LargeFileBenchmarkTests: XCTestCase {
  private lazy var configuration = PerformanceBenchmarkConfiguration()

  func testCLIValidationCompletesWithinPerformanceBudget() throws {
    let fixture = try LargeFileBenchmarkFixture.make(configuration: configuration)
    let strictResults = try measureCLIValidationBenchmark(
      fixture: fixture,
      configuration: configuration,
      options: .strict
    )

    XCTAssertLessThanOrEqual(
      strictResults.averageDuration,
      configuration.cliDurationBudgetSeconds(),
      "Strict-mode CLI validation exceeded budget for payload of \(configuration.payloadBytes) bytes"
    )

    XCTAssertEqual(
      strictResults.eventCount,
      fixture.expectedEventCount,
      "Strict-mode CLI validation produced unexpected event count"
    )
  }

  func testCLIValidationLenientModePerformanceStaysWithinToleranceBudget() throws {
    let fixture = try LargeFileBenchmarkFixture.make(configuration: configuration)

    let strictResults = try measureCLIValidationBenchmark(
      fixture: fixture,
      configuration: configuration,
      options: .strict
    )
    let tolerantResults = try measureCLIValidationBenchmark(
      fixture: fixture,
      configuration: configuration,
      options: .tolerant
    )

    let strictAverage = max(strictResults.averageDuration, .ulpOfOne)
    let tolerantAverage = tolerantResults.averageDuration
    let ratio = tolerantAverage / strictAverage
    let strictAverageString = String(format: "%.3f", strictAverage)
    let tolerantAverageString = String(format: "%.3f", tolerantAverage)
    let ratioString = String(format: "%.3f", ratio)
    print("CLI strict average duration: \(strictAverageString)s")
    print("CLI tolerant average duration: \(tolerantAverageString)s (ratio: \(ratioString))")
    XCTAssertLessThanOrEqual(
      ratio,
      configuration.tolerantDurationOverheadBudget(),
      "Lenient mode CLI validation exceeded allowed runtime overhead"
    )

    if let strictPeak = strictResults.peakMemoryBytes,
      let tolerantPeak = tolerantResults.peakMemoryBytes
    {
      let overhead = tolerantPeak > strictPeak ? tolerantPeak - strictPeak : 0
      let overheadMiB = Double(overhead) / 1_048_576
      let overheadString = String(format: "%.2f", overheadMiB)
      print("CLI tolerant peak memory overhead: \(overheadString) MiB")
      XCTAssertLessThanOrEqual(
        overhead,
        configuration.tolerantAdditionalMemoryBudgetBytes(),
        "Lenient mode CLI validation exceeded allowed memory overhead"
      )
    }

    XCTAssertEqual(
      tolerantResults.eventCount,
      fixture.expectedEventCount,
      "Lenient mode CLI validation produced unexpected event count"
    )
  }

  #if canImport(Combine)
    @MainActor
    func testAppStreamingPipelineDeliversUpdatesWithinLatencyBudget() throws {
      let fixture = try LargeFileBenchmarkFixture.make(configuration: configuration)

      performBenchmark(iterations: configuration.iterationCount) {
        let pipeline = ParsePipeline.live()
        let reader = try ChunkedFileReader(fileURL: fixture.url)
        let store = ParseTreeStore()
        let expectation = expectation(description: "Stream completed")
        var cancellables: Set<AnyCancellable> = []
        var firstEventLatency: TimeInterval?
        let start = Date()

        store.$snapshot
          .dropFirst()
          .sink { snapshot in
            if firstEventLatency == nil,
              snapshot.lastUpdatedAt > .distantPast
            {
              firstEventLatency = Date().timeIntervalSince(start)
            }
          }
          .store(in: &cancellables)

        store.$state
          .dropFirst()
          .sink { state in
            if state == .finished {
              expectation.fulfill()
            }
          }
          .store(in: &cancellables)

        store.start(
          pipeline: pipeline,
          reader: reader,
          context: .init(source: fixture.url)
        )

        wait(for: [expectation], timeout: configuration.cliDurationBudgetSeconds() * 2)

        XCTAssertEqual(store.state, .finished)
        XCTAssertFalse(store.snapshot.nodes.isEmpty)
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
    func testAppStreamingPipelineDeliversUpdatesWithinLatencyBudget() throws {
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

extension LargeFileBenchmarkTests {
  fileprivate func performBenchmark(iterations: Int, block: () throws -> Void) {
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

  fileprivate func runRandomSliceBenchmark(
    readerName: String,
    fixture: LargeFileBenchmarkFixture,
    makeReader: (URL) throws -> any RandomAccessReader
  ) throws {
    let scenarios = RandomSliceBenchmarkScenario.makeDefaultScenarios(
      payloadBytes: configuration.payloadBytes)

    let lengthProbe = try makeReader(fixture.url)
    let fileLength = lengthProbe.length
    struct PreparedScenario {
      let scenario: RandomSliceBenchmarkScenario
      let requests: [RandomSliceRequest]
      let expectedBytes: Int
    }
    let preparedScenarios: [PreparedScenario] = scenarios.map { scenario in
      let requests = scenario.makeRequests(fileLength: fileLength)
      XCTAssertFalse(
        requests.isEmpty,
        "Scenario \(scenario.name) produced no slice requests for \(readerName)")
      let expectedBytes = requests.reduce(into: 0) { $0 += $1.count }
      return PreparedScenario(
        scenario: scenario,
        requests: requests,
        expectedBytes: expectedBytes
      )
    }

    performBenchmark(iterations: configuration.iterationCount) {
      for prepared in preparedScenarios {
        let reader = try makeReader(fixture.url)
        let bytesRead = try executeRandomSliceRequests(
          prepared.requests,
          using: reader,
          readerName: readerName,
          scenarioName: prepared.scenario.name
        )
        XCTAssertEqual(
          bytesRead,
          prepared.expectedBytes,
          "Reader \(readerName) returned truncated data while benchmarking scenario \(prepared.scenario.name)"
        )
      }
    }

    for prepared in preparedScenarios {
      let summary = prepared.scenario.makeSummary(
        readerName: readerName,
        totalBytesPerIteration: prepared.expectedBytes,
        requestCount: prepared.requests.count,
        readerLength: fileLength
      )
      print(summary)
    }
  }

  fileprivate func measureCLIValidationBenchmark(
    fixture: LargeFileBenchmarkFixture,
    configuration: PerformanceBenchmarkConfiguration,
    options: ParsePipeline.Options
  ) throws -> CLIBenchmarkResult {
    let environment = makeCLIEnvironment(options: options)
    var durations: [TimeInterval] = []
    durations.reserveCapacity(configuration.iterationCount)
    var peakMemory: UInt64 = currentMemoryUsageBytes() ?? 0
    var eventCount = 0

    for _ in 0..<configuration.iterationCount {
      let start = Date()
      try runValidateCommand(on: fixture.url, environment: environment)
      let duration = Date().timeIntervalSince(start)
      durations.append(duration)
      if let usage = currentMemoryUsageBytes() {
        peakMemory = max(peakMemory, usage)
      }
      eventCount = try drainEvents(
        using: environment.parsePipeline,
        fileURL: fixture.url
      )
    }

    return CLIBenchmarkResult(
      durations: durations,
      peakMemoryBytes: peakMemory == 0 ? nil : peakMemory,
      eventCount: eventCount
    )
  }

  fileprivate func executeRandomSliceRequests(
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
        let prefix =
          "Reader \(readerName) failed random slice scenario \(scenarioName) (offset: \(request.offset), count: \(request.count))"
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

  fileprivate func runValidateCommand(
    on fileURL: URL,
    environment: ISOInspectorCLIEnvironment
  ) throws {
    let expectation = expectation(description: "validate command completed")
    let capturedError = LockedValueBox<Error?>(nil)

    Task {
      await MainActor.run {
        ISOInspectorCommand.contextFactory = { _ in
          ISOInspectorCommandContext(environment: environment)
        }
        ISOInspectorCommandContextStore.reset()
      }
      do {
        var command = try ISOInspectorCommand.Commands.Validate.parse([fileURL.path])
        try await command.run()
      } catch {
        capturedError.withValue { $0 = error }
      }
      await MainActor.run {
        ISOInspectorCommandContextStore.reset()
        ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
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

private func makeCLIEnvironment(options: ParsePipeline.Options) -> ISOInspectorCLIEnvironment {
  ISOInspectorCLIEnvironment(
    refreshCatalog: { _, _ in },
    makeReader: { url in try ChunkedFileReader(fileURL: url) },
    parsePipeline: .live(options: options),
    formatter: EventConsoleFormatter(),
    print: { _ in },
    printError: { _ in }
  )
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

private struct CLIBenchmarkResult {
  let durations: [TimeInterval]
  let peakMemoryBytes: UInt64?
  let eventCount: Int

  var averageDuration: TimeInterval {
    guard !durations.isEmpty else { return 0 }
    let sum = durations.reduce(0, +)
    return sum / Double(durations.count)
  }
}

private func currentMemoryUsageBytes() -> UInt64? {
  #if os(Linux)
    guard let status = try? String(contentsOfFile: "/proc/self/status", encoding: .utf8) else {
      return nil
    }
    for line in status.split(whereSeparator: \.isNewline) where line.hasPrefix("VmRSS:") {
      let components = line.split(separator: " ", omittingEmptySubsequences: true)
      if components.count >= 2, let value = UInt64(components[1]) {
        return value * 1024
      }
    }
    return nil
  #else
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(
      MemoryLayout.size(ofValue: info) / MemoryLayout<natural_t>.size)
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    guard kerr == KERN_SUCCESS else {
      return nil
    }
    return UInt64(info.resident_size)
  #endif
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
    let expectedSize = LargeFileBenchmarkFixtureBuilder.expectedFileSize(
      payloadBytes: payloadBytes)
    if fileManager.fileExists(atPath: url.path) {
      if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
        let size = attributes[FileAttributeKey.size] as? NSNumber,
        size.intValue == expectedSize
      {
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
    appendUInt32(0x0000_0200, to: &data)
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
      ),
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
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
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
