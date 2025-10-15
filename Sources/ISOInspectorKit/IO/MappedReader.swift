import Foundation

/// Reader that performs bounds-checked random access over memory-mapped file contents.
///
/// The reader prefers mapping the specified file into memory using `Data(mappedIfSafe:)`
/// and falls back to eager loading if mapping is unavailable on the current platform
/// or for the given file system volume. The file contents are treated as immutable,
/// making the instance safe to share across threads for read-only access.
public final class MappedReader: RandomAccessReader {
    public enum Error: Swift.Error {
        case fileNotFound
        case mappingFailed(underlying: Swift.Error)
        case invalidOffset(Int64)
        case invalidCount(Int)
        case requestedRangeOutOfBounds
    }

    public let length: Int64
    private let storage: Data

    /// Creates a reader for the file at `fileURL`.
    /// - Parameter fileURL: Location of the file to map.
    public convenience init(fileURL: URL) throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw Error.fileNotFound
        }

        do {
            let data = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
            self.init(data: data)
        } catch {
            do {
                let data = try Data(contentsOf: fileURL)
                self.init(data: data)
            } catch {
                throw Error.mappingFailed(underlying: error)
            }
        }
    }

    init(data: Data) {
        self.storage = data
        self.length = Int64(data.count)
    }

    public func read(at offset: Int64, count: Int) throws -> Data {
        guard offset >= 0 else { throw Error.invalidOffset(offset) }
        guard count >= 0 else { throw Error.invalidCount(count) }
        guard count > 0 else { return Data() }
        guard offset < length else { throw Error.requestedRangeOutOfBounds }

        let endOffset = offset + Int64(count)
        guard endOffset <= length else { throw Error.requestedRangeOutOfBounds }

        let start = Int(offset)
        let end = start + count
        return storage.subdata(in: start..<end)
    }
}
