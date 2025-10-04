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
