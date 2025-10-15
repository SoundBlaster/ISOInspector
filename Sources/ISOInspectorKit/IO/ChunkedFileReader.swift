import Foundation

/// Reader that performs buffered, chunk-aligned file IO to minimise allocation while
/// supporting random access.
public final class ChunkedFileReader: RandomAccessReader {
    public static let defaultChunkSize = 1_048_576

    public enum Error: Swift.Error {
        case ioError(underlying: Swift.Error)
    }

    let file: ChunkedFileReaderRandomAccessFile
    public let length: Int64
    let chunkSize: Int

    private var cachedChunkOffset: Int64?
    private var cachedChunkData: Data
    private let closeHandler: (() -> Void)?

    public convenience init(fileURL: URL, chunkSize: Int = ChunkedFileReader.defaultChunkSize) throws {
        let handle = try FileHandle(forReadingFrom: fileURL)
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        guard let fileSize = attributes[.size] as? NSNumber else {
            try? handle.close()
            throw Error.ioError(underlying: CocoaError(.fileReadUnknown))
        }
        self.init(
            length: fileSize.int64Value,
            chunkSize: chunkSize,
            file: FileHandleAdapter(handle: handle),
            closeHandler: { try? handle.close() }
        )
    }

    init(length: Int64, chunkSize: Int, file: ChunkedFileReaderRandomAccessFile, closeHandler: (() -> Void)? = nil) {
        precondition(chunkSize > 0, "Chunk size must be positive")
        precondition(length >= 0, "Length must be non-negative")
        self.length = length
        self.chunkSize = chunkSize
        self.file = file
        self.closeHandler = closeHandler
        self.cachedChunkData = Data()
    }

    deinit {
        closeHandler?()
    }

    public func read(at offset: Int64, count: Int) throws -> Data {
        guard offset >= 0 else {
            throw RandomAccessReaderError.boundsError(.invalidOffset(offset))
        }
        guard count >= 0 else {
            throw RandomAccessReaderError.boundsError(.invalidCount(count))
        }
        guard count > 0 else { return Data() }
        guard let count64 = Int64(exactly: count) else {
            throw RandomAccessReaderError.overflowError
        }
        let upperResult = offset.addingReportingOverflow(count64)
        guard upperResult.overflow == false else {
            throw RandomAccessReaderError.overflowError
        }
        let upperBound = upperResult.partialValue
        guard offset < length else {
            throw RandomAccessReaderError.boundsError(
                .requestedRangeOutOfBounds(offset: offset, count: count)
            )
        }
        guard upperBound <= length else {
            throw RandomAccessReaderError.boundsError(
                .requestedRangeOutOfBounds(offset: offset, count: count)
            )
        }

        var remaining = count
        var currentOffset = offset
        var result = Data(capacity: count)

        while remaining > 0 {
            let chunkOffset = alignedOffset(for: currentOffset)
            let chunk = try loadChunk(at: chunkOffset)
            let startIndex = Int(currentOffset - chunkOffset)
            let available = chunk.count - startIndex
            guard available > 0 else {
                throw RandomAccessReaderError.ioError(underlying: CocoaError(.fileReadUnknown))
            }
            let portion = min(available, remaining)
            result.append(chunk[startIndex..<(startIndex + portion)])
            remaining -= portion
            currentOffset += Int64(portion)
        }

        return result
    }

    private func alignedOffset(for position: Int64) -> Int64 {
        let chunk = Int64(chunkSize)
        return (position / chunk) * chunk
    }

    private func loadChunk(at offset: Int64) throws -> Data {
        if cachedChunkOffset == offset, !cachedChunkData.isEmpty {
            return cachedChunkData
        }

        do {
            try file.seek(toOffset: UInt64(offset))
            var buffer = Data(repeating: 0, count: chunkSize)
            let readCount = try buffer.withUnsafeMutableBytes { pointer -> Int in
                try file.read(into: pointer, requestedCount: chunkSize)
            }
            cachedChunkOffset = offset
            cachedChunkData = buffer.prefix(readCount)
            return cachedChunkData
        } catch {
            throw RandomAccessReaderError.ioError(underlying: error)
        }
    }
}

protocol ChunkedFileReaderRandomAccessFile {
    func seek(toOffset offset: UInt64) throws
    func read(into buffer: UnsafeMutableRawBufferPointer, requestedCount: Int) throws -> Int
}

private final class FileHandleAdapter: ChunkedFileReaderRandomAccessFile {
    let handle: FileHandle

    init(handle: FileHandle) {
        self.handle = handle
    }

    func seek(toOffset offset: UInt64) throws {
        try handle.seek(toOffset: offset)
    }

    func read(into buffer: UnsafeMutableRawBufferPointer, requestedCount: Int) throws -> Int {
        let data = try handle.read(upToCount: requestedCount) ?? Data()
        if let baseAddress = buffer.baseAddress, !data.isEmpty {
            data.copyBytes(to: baseAddress.assumingMemoryBound(to: UInt8.self), count: data.count)
        }
        return data.count
    }
}
