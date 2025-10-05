import Foundation
@testable import ISOInspectorKit

struct InMemoryRandomAccessReader: RandomAccessReader {
    enum Error: Swift.Error {
        case requestedRangeOutOfBounds
    }

    let data: Data

    var length: Int64 { Int64(data.count) }

    func read(at offset: Int64, count: Int) throws -> Data {
        guard offset >= 0, count >= 0 else {
            throw Error.requestedRangeOutOfBounds
        }
        let lower = Int(offset)
        guard lower >= 0, lower <= data.count else {
            throw Error.requestedRangeOutOfBounds
        }
        let upper = min(data.count, lower + count)
        return data.subdata(in: lower..<upper)
    }
}
