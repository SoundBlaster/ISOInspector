import Foundation

/// Protocol describing the minimal interface necessary for the ISOInspector parser to
/// perform random-access reads from a binary data source.
public protocol RandomAccessReader {
    /// Total length of the readable data in bytes.
    var length: Int64 { get }

    /// Reads `count` bytes starting at `offset` and returns them as `Data`.
    /// - Parameters:
    ///   - offset: Absolute byte offset in the data source.
    ///   - count: Number of bytes to read.
    /// - Returns: A `Data` value containing the requested bytes.
    /// - Throws: Reader-specific errors when the operation cannot be completed.
    func read(at offset: Int64, count: Int) throws -> Data
}

/// Shared error type surfaced by `RandomAccessReader` conformers.
public enum RandomAccessReaderError: Swift.Error, Equatable, Sendable {
    case ioError(underlying: Swift.Error)
    case boundsError(RandomAccessReaderBoundsError)
    case overflowError

    public static func == (lhs: RandomAccessReaderError, rhs: RandomAccessReaderError) -> Bool {
        switch (lhs, rhs) {
        case (.overflowError, .overflowError):
            return true
        case let (.boundsError(lhsError), .boundsError(rhsError)):
            return lhsError == rhsError
        case (.ioError, .ioError):
            return true
        default:
            return false
        }
    }
}

/// Bounds validation errors thrown by `RandomAccessReader` conformers.
public enum RandomAccessReaderBoundsError: Equatable, Sendable {
    case invalidOffset(Int64)
    case invalidCount(Int)
    case requestedRangeOutOfBounds(offset: Int64, count: Int)
}

/// Errors thrown by helper decoding routines built on top of `RandomAccessReader`.
public enum RandomAccessReaderValueDecodingError: Swift.Error, Equatable {
    case truncatedRead(expected: Int, actual: Int)
    case invalidFourCharacterCode(Data)
}

public extension RandomAccessReader {
    func readUInt32(at offset: Int64) throws -> UInt32 {
        try readInteger(at: offset)
    }

    func readUInt64(at offset: Int64) throws -> UInt64 {
        try readInteger(at: offset)
    }

    func readFourCC(at offset: Int64) throws -> IIFourCharCode {
        let byteCount = 4
        let data = try read(at: offset, count: byteCount)
        guard data.count == byteCount else {
            throw RandomAccessReaderValueDecodingError.truncatedRead(expected: byteCount, actual: data.count)
        }
        do {
            return try IIFourCharCode(data: data)
        } catch {
            throw RandomAccessReaderValueDecodingError.invalidFourCharacterCode(data)
        }
    }

    private func readInteger<T: FixedWidthInteger>(at offset: Int64) throws -> T {
        let expected = MemoryLayout<T>.size
        let data = try read(at: offset, count: expected)
        guard data.count == expected else {
            throw RandomAccessReaderValueDecodingError.truncatedRead(expected: expected, actual: data.count)
        }
        return data.reduce(T(0)) { partialResult, byte in
            (partialResult << 8) | T(byte)
        }
    }
}
