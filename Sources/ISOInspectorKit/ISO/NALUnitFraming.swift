import Foundation

/// Locates length-prefixed NAL units inside one already-delimited media sample.
/// This checks framing only; it does not validate or decode the NAL payload.
enum NALUnitFraming {
    enum Failure: Error, Equatable {
        case invalidLengthWidth(Int)
        case truncatedLength(offset: Int, expected: Int, available: Int)
        case emptyUnit(offset: Int)
        case truncatedUnit(offset: Int, declared: UInt64, available: Int)
    }

    /// Checks a file-backed sample without reading the NAL payloads into memory.
    static func validate(reader: any RandomAccessReader, range: Range<Int64>, lengthBytes: Int) throws {
        guard (1...4).contains(lengthBytes) else { throw Failure.invalidLengthWidth(lengthBytes) }
        var cursor = range.lowerBound
        while cursor < range.upperBound {
            try Task.checkCancellation()
            let available = range.upperBound - cursor
            let relativeOffset = Int(cursor - range.lowerBound)
            guard available >= lengthBytes else {
                throw Failure.truncatedLength(offset: relativeOffset, expected: lengthBytes, available: Int(available))
            }
            let data = try reader.read(at: cursor, count: lengthBytes)
            try Task.checkCancellation()
            guard data.count == lengthBytes else {
                throw RandomAccessReaderValueDecodingError.truncatedRead(expected: lengthBytes, actual: data.count)
            }
            let declared = data.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            guard declared > 0 else { throw Failure.emptyUnit(offset: relativeOffset) }
            cursor += Int64(lengthBytes)
            let remaining = range.upperBound - cursor
            guard declared <= UInt64(remaining) else {
                throw Failure.truncatedUnit(offset: Int(cursor - range.lowerBound), declared: declared, available: Int(remaining))
            }
            cursor += Int64(declared)
        }
    }

}
