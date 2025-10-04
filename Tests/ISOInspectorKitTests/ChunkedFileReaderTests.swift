import XCTest
@testable import ISOInspectorKit

final class ChunkedFileReaderTests: XCTestCase {
    private var temporaryURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
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
            guard case ChunkedFileReader.Error.requestedRangeOutOfBounds? = error as? ChunkedFileReader.Error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }

    func testUnderlyingReadErrorIsSurfaced() throws {
        final class FailingFile: ChunkedFileReaderRandomAccessFile {
            func seek(toOffset offset: UInt64) throws {}
            func read(into buffer: UnsafeMutableRawBufferPointer, requestedCount: Int) throws -> Int {
                throw TestError.failure
            }
        }

        enum TestError: Error { case failure }

        let reader = ChunkedFileReader(
            length: 1024,
            chunkSize: 128,
            file: FailingFile()
        )

        XCTAssertThrowsError(try reader.read(at: 0, count: 16)) { error in
            guard case let ChunkedFileReader.Error.ioError(underlying)? = error as? ChunkedFileReader.Error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            XCTAssertTrue(underlying is TestError)
        }
    }
}
