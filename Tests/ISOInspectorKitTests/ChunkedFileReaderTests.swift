import XCTest

@testable import ISOInspectorKit

final class ChunkedFileReaderTests: XCTestCase {
    private var temporaryURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        temporaryURL = directory.appendingPathComponent("fixture.bin")
    }

    override func tearDownWithError() throws {
        if let url = temporaryURL {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
        temporaryURL = nil
        try super.tearDownWithError()
    }

    func testSequentialChunkReadsRespectConfiguredChunkSize() throws {
        let chunkSize = 256
        let totalChunks = 5
        let data = Data((0..<(chunkSize * totalChunks)).map { UInt8($0 % 251) })
        try data.write(to: temporaryURL)

        let reader = try ChunkedFileReader(fileURL: temporaryURL, chunkSize: chunkSize)

        let first = try reader.read(at: 0, count: chunkSize)
        XCTAssertEqual(first, data.subdata(in: 0..<chunkSize))

        let second = try reader.read(at: Int64(chunkSize), count: chunkSize)
        XCTAssertEqual(second, data.subdata(in: chunkSize..<(chunkSize * 2)))
    }

    func testReadAllowsSeekingToArbitraryOffsets() throws {
        let payload = Data((0..<1024).map { UInt8(($0 * 3) % 255) })
        try payload.write(to: temporaryURL)

        let reader = try ChunkedFileReader(fileURL: temporaryURL, chunkSize: 128)

        let slice = try reader.read(at: 73, count: 50)
        XCTAssertEqual(slice, payload.subdata(in: 73..<123))
    }

    func testPartialChunkAtEndOfFile() throws {
        let chunkSize = 512
        let totalSize = (chunkSize * 2) + 123
        let payload = Data((0..<totalSize).map { UInt8(($0 * 7) % 253) })
        try payload.write(to: temporaryURL)

        let reader = try ChunkedFileReader(fileURL: temporaryURL, chunkSize: chunkSize)

        let tail = try reader.read(at: Int64(totalSize - 123), count: 123)
        XCTAssertEqual(tail, payload.suffix(123))
    }

    func testReadSpanningMultipleChunksReturnsContiguousBytes() throws {
        let chunkSize = 128
        let payload = Data((0..<512).map { UInt8($0 % 211) })
        try payload.write(to: temporaryURL)

        let reader = try ChunkedFileReader(fileURL: temporaryURL, chunkSize: chunkSize)

        let offset = 60
        let count = 200
        let slice = try reader.read(at: Int64(offset), count: count)

        XCTAssertEqual(slice, payload.subdata(in: offset..<(offset + count)))
    }

    func testReadBeyondEndOfFileThrows() throws {
        let bytes = Data((0..<400).map { UInt8($0 % 233) })
        try bytes.write(to: temporaryURL)

        let reader = try ChunkedFileReader(fileURL: temporaryURL, chunkSize: 128)

        XCTAssertThrowsError(try reader.read(at: 390, count: 32)) { error in
            guard let readerError = error as? RandomAccessReaderError else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            guard case .boundsError(let bounds) = readerError else {
                XCTFail("Unexpected error: \(readerError)")
                return
            }
            XCTAssertEqual(bounds, .requestedRangeOutOfBounds(offset: 390, count: 32))
        }
    }

    func testNegativeOffsetThrowsBoundsError() throws {
        let bytes = Data((0..<64).map { UInt8($0) })
        try bytes.write(to: temporaryURL)

        let reader = try ChunkedFileReader(fileURL: temporaryURL, chunkSize: 32)

        XCTAssertThrowsError(try reader.read(at: -1, count: 4)) { error in
            guard let readerError = error as? RandomAccessReaderError else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            guard case .boundsError(let bounds) = readerError else {
                XCTFail("Unexpected error: \(readerError)")
                return
            }
            XCTAssertEqual(bounds, .invalidOffset(-1))
        }
    }

    func testNegativeCountThrowsBoundsError() throws {
        let bytes = Data((0..<64).map { UInt8($0) })
        try bytes.write(to: temporaryURL)

        let reader = try ChunkedFileReader(fileURL: temporaryURL, chunkSize: 32)

        XCTAssertThrowsError(try reader.read(at: 0, count: -4)) { error in
            guard let readerError = error as? RandomAccessReaderError else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            guard case .boundsError(let bounds) = readerError else {
                XCTFail("Unexpected error: \(readerError)")
                return
            }
            XCTAssertEqual(bounds, .invalidCount(-4))
        }
    }

    func testOverflowingRangeThrowsOverflowError() throws {
        let reader = ChunkedFileReader(
            length: Int64(128), chunkSize: 64,
            file: TestFileHandle(readHandler: { _ in Data(repeating: 0, count: 64) }))

        XCTAssertThrowsError(try reader.read(at: Int64.max - 4, count: 10)) { error in
            guard let readerError = error as? RandomAccessReaderError else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            guard case .overflowError = readerError else {
                XCTFail("Unexpected error: \(readerError)")
                return
            }
        }
    }

    func testUnderlyingReadErrorIsSurfaced() throws {
        final class FailingFile: ChunkedFileReaderRandomAccessFile {
            func seek(toOffset offset: UInt64) throws {}
            func read(into buffer: UnsafeMutableRawBufferPointer, requestedCount: Int) throws -> Int
            { throw TestError.failure }
        }

        enum TestError: Error { case failure }

        let reader = ChunkedFileReader(length: 1024, chunkSize: 128, file: FailingFile())

        XCTAssertThrowsError(try reader.read(at: 0, count: 16)) { error in
            guard let readerError = error as? RandomAccessReaderError else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            guard case .ioError(let underlying) = readerError else {
                XCTFail("Unexpected error: \(readerError)")
                return
            }
            XCTAssertTrue(underlying is TestError)
        }
    }
}

private final class TestFileHandle: ChunkedFileReaderRandomAccessFile {
    private let readHandler: (Int) throws -> Data
    private var position: UInt64 = 0

    init(readHandler: @escaping (Int) throws -> Data) { self.readHandler = readHandler }

    func seek(toOffset offset: UInt64) throws { position = offset }

    func read(into buffer: UnsafeMutableRawBufferPointer, requestedCount: Int) throws -> Int {
        let data = try readHandler(requestedCount)
        position += UInt64(min(requestedCount, data.count))
        if let baseAddress = buffer.baseAddress, !data.isEmpty {
            data.copyBytes(to: baseAddress.assumingMemoryBound(to: UInt8.self), count: data.count)
        }
        return data.count
    }
}
