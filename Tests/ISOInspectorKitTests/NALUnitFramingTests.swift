import Foundation
import Testing

@testable import ISOInspectorKit

@Suite struct NALUnitFramingTests {
    @Test func validatesMultipleUnits() throws {
        try validate([0, 0, 0, 2, 0x65, 0x11, 0, 0, 0, 1, 0x41], lengthBytes: 4)
    }

    @Test func supportsOneAndTwoByteLengths() throws {
        try validate([2, 0x65, 0x11], lengthBytes: 1)
        try validate([0, 1, 0x41], lengthBytes: 2)
    }

    @Test func reportsTruncatedLengthAtItsOffset() {
        #expect(throws: NALUnitFraming.Failure.truncatedLength(offset: 4, expected: 2, available: 1)) {
            try validate([0, 2, 0x65, 0x11, 0], lengthBytes: 2)
        }
    }

    @Test func reportsLengthBeyondSampleBoundary() {
        #expect(throws: NALUnitFraming.Failure.truncatedUnit(offset: 1, declared: 4, available: 2)) {
            try validate([4, 0x65, 0x11], lengthBytes: 1)
        }
    }

    @Test func rejectsZeroLengthAndInvalidLengthWidth() {
        #expect(throws: NALUnitFraming.Failure.emptyUnit(offset: 0)) { try validate([0], lengthBytes: 1) }
        #expect(throws: NALUnitFraming.Failure.invalidLengthWidth(0)) { try validate([0], lengthBytes: 0) }
    }

    @Test func reportsHugeLengthWithoutIntegerOverflow() {
        #expect(throws: NALUnitFraming.Failure.truncatedUnit(offset: 4, declared: 4_294_967_295, available: 1)) {
            try validate([0xff, 0xff, 0xff, 0xff, 0x65], lengthBytes: 4)
        }
    }

    @Test func reportsOffsetRelativeToSample() {
        let reader = InMemoryRandomAccessReader(data: Data([0, 0, 0xff, 0xff, 0, 0]))
        #expect(throws: NALUnitFraming.Failure.truncatedUnit(offset: 2, declared: 65_535, available: 2)) {
            try NALUnitFraming.validate(reader: reader, range: 2..<6, lengthBytes: 2)
        }
    }

    @Test func propagatesReaderErrors() {
        #expect(throws: ReadFailure.unavailable) {
            try NALUnitFraming.validate(reader: FailingReader(), range: 0..<4, lengthBytes: 4)
        }
    }

    @Test func cancellationDuringReadDoesNotBecomeAFramingError() async {
        let task = Task {
            try NALUnitFraming.validate(reader: CancellingReader(), range: 0..<4, lengthBytes: 4)
        }
        switch await task.result {
        case .success: Issue.record("Expected cancellation")
        case .failure(let error): #expect(error is CancellationError)
        }
    }

    private enum ReadFailure: Error { case unavailable }

    private struct FailingReader: RandomAccessReader {
        let length: Int64 = 4
        func read(at offset: Int64, count: Int) throws -> Data { throw ReadFailure.unavailable }
    }

    private struct CancellingReader: RandomAccessReader {
        let length: Int64 = 4
        func read(at offset: Int64, count: Int) throws -> Data {
            withUnsafeCurrentTask { $0?.cancel() }
            return Data(repeating: 0xff, count: count)
        }
    }

    private func validate(_ bytes: [UInt8], lengthBytes: Int) throws {
        try NALUnitFraming.validate(reader: InMemoryRandomAccessReader(data: Data(bytes)),
                                    range: 0..<Int64(bytes.count), lengthBytes: lengthBytes)
    }
}
