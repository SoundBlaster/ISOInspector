import Foundation
import Synchronization
import Testing

@testable import ISOInspectorKit

@Suite struct ParsePipelineConcurrencyTests {
    @Test func cancellingConsumerCancelsProducerWhileReaderIsBlocked() async throws {
        let reader = GatedReader()
        defer { reader.release() }
        let stream = ParsePipeline.live().events(for: reader)
        let consumer = Task { for try await _ in stream {} }

        try #require(await reader.waitForRead(), "Producer did not enter the reader")
        consumer.cancel()
        try await consumer.value
        reader.release()

        try #require(await reader.waitForObservation(), "Producer did not resume")
        #expect(reader.wasCancelled == true)
    }

    @Test func cancellingParentCancelsGroupConsumerAndStreamProducer() async throws {
        let reader = GatedReader()
        defer { reader.release() }
        let stream = ParsePipeline.live().events(for: reader)
        let parent = Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { for try await _ in stream {} }
                try await group.waitForAll()
            }
        }

        try #require(await reader.waitForRead(), "Producer did not enter the reader")
        parent.cancel()
        try await parent.value
        reader.release()

        try #require(await reader.waitForObservation(), "Producer did not resume")
        #expect(reader.wasCancelled == true)
    }

    @Test func producerContinuesNormallyWhenConsumerIsNotCancelled() async throws {
        let reader = GatedReader()
        defer { reader.release() }
        let stream = ParsePipeline.live().events(for: reader)
        let consumer = Task {
            var events: [ParseEvent] = []
            for try await event in stream { events.append(event) }
            return events
        }

        try #require(await reader.waitForRead(), "Producer did not enter the reader")
        reader.release()
        try #require(await reader.waitForObservation(), "Producer did not resume")
        let events = try await consumer.value

        #expect(reader.wasCancelled == false)
        #expect(events.count == 2)
        if case .willStartBox(let header, _) = events.first?.kind {
            #expect(header.type.rawValue == "free")
        } else { Issue.record("Expected a box start event") }
        if case .didFinishBox = events.last?.kind {} else {
            Issue.record("Expected a box finish event")
        }
    }

    @Test func readerFailureAfterAnEventReachesTheConsumer() async throws {
        let reader = FailingSecondBoxReader()
        var iterator = ParsePipeline.live().events(for: reader).makeAsyncIterator()

        let first = try #require(await iterator.next())
        let second = try #require(await iterator.next())
        if case .willStartBox = first.kind {} else { Issue.record("Expected box start") }
        if case .didFinishBox = second.kind {} else { Issue.record("Expected box finish") }

        do {
            _ = try await iterator.next()
            Issue.record("Expected the reader failure")
        } catch BoxHeaderDecodingError.readerError(let underlying) {
            #expect(underlying is FailingSecondBoxReader.ReadFailure)
        } catch { Issue.record("Unexpected error: \(error)") }
    }
}

private let emptyFreeBox = Data([0, 0, 0, 8, 0x66, 0x72, 0x65, 0x65])

private final class GatedReader: RandomAccessReader {
    let length: Int64 = 8
    private let entered = DispatchSemaphore(value: 0)
    private let gate = DispatchSemaphore(value: 0)
    private let observed = DispatchSemaphore(value: 0)
    private let observation = Mutex<Bool?>(nil)

    var wasCancelled: Bool? { observation.withLock { $0 } }

    func read(at offset: Int64, count: Int) throws -> Data {
        if offset == 0 {
            entered.signal()
            guard gate.wait(timeout: .now() + 10) == .success else { throw GateTimeout() }
            observation.withLock { $0 = Task.isCancelled }
            observed.signal()
        }
        return emptyFreeBox.subdata(in: Int(offset)..<(Int(offset) + count))
    }

    func release() { gate.signal() }
    func waitForRead() async -> Bool { await wait(for: entered) }
    func waitForObservation() async -> Bool { await wait(for: observed) }

    private func wait(for semaphore: DispatchSemaphore) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: semaphore.wait(timeout: .now() + 10) == .success)
            }
        }
    }

    private struct GateTimeout: Error {}
}

private struct FailingSecondBoxReader: RandomAccessReader {
    struct ReadFailure: Error {}
    let length: Int64 = 16

    func read(at offset: Int64, count: Int) throws -> Data {
        guard offset < 8 else { throw ReadFailure() }
        return emptyFreeBox.subdata(in: Int(offset)..<(Int(offset) + count))
    }
}
