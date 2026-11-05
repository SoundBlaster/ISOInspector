import Dispatch
import Foundation
import Synchronization
import Testing

@testable import ISOInspectorKit

@Suite(.serialized) struct ReadCancellationTests {
    @Test func externalCancellationWaitsForCurrentReadAndStopsBeforeTheNextChunk() async throws {
        let file = BlockingReadFile()
        defer { file.release.signal() }
        let reader = ChunkedFileReader(length: 16, chunkSize: 8, file: file)
        let task = Task { try reader.read(at: 0, count: 16) }

        let entered = await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let entered = file.entered.wait(timeout: .now() + 5) == .success
                task.cancel()
                file.release.signal()
                continuation.resume(returning: entered)
            }
        }
        try #require(entered, "Reader did not enter the first system read")
        switch await task.result {
        case .success: Issue.record("A cancelled read returned bytes")
        case .failure(let error): #expect(error is CancellationError)
        }
        #expect(file.readCount == 1)
    }

    @Test func cancellingDuringReadStopsBeforeTheNextChunkAndDoesNotCacheIt() async throws {
        let file = CancellingReadFile()
        let reader = ChunkedFileReader(length: 16, chunkSize: 8, file: file)
        let task = Task { try reader.read(at: 0, count: 16) }

        switch await task.result {
        case .success: Issue.record("A cancelled read returned bytes")
        case .failure(let error): #expect(error is CancellationError)
        }
        #expect(file.readCount == 1)

        // A subsequent uncancelled read must not reuse a cancelled chunk.
        let bytes = try reader.read(at: 0, count: 8)
        #expect(bytes == Data(repeating: 0x42, count: 8))
        #expect(file.readCount == 2)
    }

    @Test func cancelledHeaderReadIsNotReportedAsCorruption() async throws {
        let file = CancellingReadFile()
        let reader = ChunkedFileReader(length: 8, chunkSize: 8, file: file)
        let issues = ParseIssueStore()
        let stream = ParsePipeline.live(options: .tolerant).events(
            for: reader, context: .init(options: .tolerant, issueStore: issues))
        var events: [ParseEvent] = []

        do {
            for try await event in stream { events.append(event) }
            Issue.record("Expected cancellation instead of normal completion")
        } catch is CancellationError {
            #expect(events.isEmpty)
            #expect(issues.makeIssueSummary().totalCount == 0)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func cancellationDuringPayloadReadDoesNotPublishABox() async throws {
        let bytes = Data([0, 0, 0, 16, 0x74, 0x65, 0x73, 0x74] + Array(repeating: 0, count: 8))
        let file = CancellingReadFile(bytes: bytes, cancelOnRead: 2)
        let reader = ChunkedFileReader(length: 16, chunkSize: 8, file: file)
        var registry = BoxParserRegistry()
        registry.register(parser: { _, reader in
            _ = try reader.read(at: 8, count: 4)
            return ParsedBoxPayload(fields: [])
        }, for: try FourCharCode("test"))
        let stream = ParsePipeline.live(registry: registry, options: .tolerant).events(for: reader)
        var events: [ParseEvent] = []

        do {
            for try await event in stream { events.append(event) }
            Issue.record("Expected cancellation instead of normal completion")
        } catch is CancellationError {
            #expect(events.isEmpty)
            #expect(file.readCount == 2)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func parserReadHelpersDoNotHideCancellation() {
        let reader = CancellationErrorReader()
        #expect(throws: CancellationError.self) {
            try BoxParserRegistry.DefaultParsers.readUInt16(reader, at: 0, end: 8)
        }
        #expect(throws: CancellationError.self) {
            try BoxParserRegistry.DefaultParsers.readInt16(reader, at: 0, end: 8)
        }
        #expect(throws: CancellationError.self) {
            try BoxParserRegistry.DefaultParsers.readUInt32(reader, at: 0, end: 8)
        }
        #expect(throws: CancellationError.self) {
            try BoxParserRegistry.DefaultParsers.readUInt64(reader, at: 0, end: 8)
        }
        #expect(throws: CancellationError.self) {
            try BoxParserRegistry.DefaultParsers.readFourCC(reader, at: 0, end: 8)
        }
    }

    @Test func parserReadHelpersDoNotHideIOErrors() {
        let reader = FailingReadReader()
        #expect(throws: FailingReadReader.ReadFailure.self) {
            try BoxParserRegistry.DefaultParsers.readUInt32(reader, at: 0, end: 8)
        }
    }

    @Test func fileTypeParserDoesNotHideIOErrors() throws {
        let header = BoxHeader(
            type: try FourCharCode("ftyp"), totalSize: 16, headerSize: 8,
            payloadRange: 8..<16, range: 0..<16, uuid: nil)
        #expect(throws: FailingReadReader.ReadFailure.self) {
            try BoxParserRegistry.DefaultParsers.fileType(header: header, reader: FailingReadReader())
        }
    }

    @Test func validationDoesNotTurnCancellationIntoAFileIssue() throws {
        let type = try FourCharCode("tkhd")
        let header = BoxHeader(
            type: type, totalSize: 16, headerSize: 8,
            payloadRange: 8..<16, range: 0..<16, uuid: nil)
        let descriptor = BoxDescriptor(
            identifier: .init(type: type, extendedType: nil), name: "Test",
            summary: "Test descriptor", category: nil, specification: nil, version: 0, flags: 0)
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0), offset: 0, metadata: descriptor)
        let validator = BoxValidator(rules: [VersionFlagsRule()])

        #expect(throws: CancellationError.self) {
            try validator.annotate(event: event, reader: CancellationErrorReader())
        }
    }

    @Test func codecValidationDoesNotHideReadCancellation() throws {
        let header = BoxHeader(
            type: try FourCharCode("stsd"), totalSize: 24, headerSize: 8,
            payloadRange: 8..<24, range: 0..<24, uuid: nil)
        let event = ParseEvent(kind: .willStartBox(header: header, depth: 0), offset: 0)
        let validator = BoxValidator(rules: [CodecConfigurationValidationRule()])

        #expect(throws: CancellationError.self) {
            try validator.annotate(event: event, reader: CancellationErrorReader())
        }
    }

    @Test func codecValidationDoesNotHideIOErrors() throws {
        let header = BoxHeader(
            type: try FourCharCode("stsd"), totalSize: 24, headerSize: 8,
            payloadRange: 8..<24, range: 0..<24, uuid: nil)
        let event = ParseEvent(kind: .willStartBox(header: header, depth: 0), offset: 0)
        let validator = BoxValidator(rules: [CodecConfigurationValidationRule()])

        #expect(throws: FailingReadReader.ReadFailure.self) {
            try validator.annotate(event: event, reader: FailingReadReader())
        }
    }
}

private final class BlockingReadFile: ChunkedFileReaderRandomAccessFile, @unchecked Sendable {
    let entered = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)
    private let count = Mutex(0)
    var readCount: Int { count.withLock { $0 } }

    func seek(toOffset offset: UInt64) throws {}
    func read(into buffer: UnsafeMutableRawBufferPointer, requestedCount: Int) throws -> Int {
        count.withLock { $0 += 1 }
        entered.signal()
        guard release.wait(timeout: .now() + 10) == .success else { throw ReadTimedOut() }
        buffer.initializeMemory(as: UInt8.self, repeating: 0x42)
        return requestedCount
    }

    private struct ReadTimedOut: Error {}
}

private struct CancellationErrorReader: RandomAccessReader {
    let length: Int64 = 8
    func read(at offset: Int64, count: Int) throws -> Data { throw CancellationError() }
}

private struct FailingReadReader: RandomAccessReader {
    struct ReadFailure: Error {}
    let length: Int64 = 8
    func read(at offset: Int64, count: Int) throws -> Data { throw ReadFailure() }
}

private final class CancellingReadFile: ChunkedFileReaderRandomAccessFile, @unchecked Sendable {
    private let count = Mutex(0)
    private let position = Mutex(0)
    private let bytes: Data
    private let cancelOnRead: Int
    var readCount: Int { count.withLock { $0 } }

    init(bytes: Data = Data(repeating: 0x42, count: 16), cancelOnRead: Int = 1) {
        self.bytes = bytes
        self.cancelOnRead = cancelOnRead
    }

    func seek(toOffset offset: UInt64) throws { position.withLock { $0 = Int(offset) } }

    func read(into buffer: UnsafeMutableRawBufferPointer, requestedCount: Int) throws -> Int {
        let current = count.withLock { value in
            value += 1
            return value
        }
        let start = position.withLock { $0 }
        let data = bytes.subdata(in: start..<min(start + requestedCount, bytes.count))
        _ = data.copyBytes(to: buffer.bindMemory(to: UInt8.self))
        if current == cancelOnRead { withUnsafeCurrentTask { $0?.cancel() } }
        return data.count
    }
}
