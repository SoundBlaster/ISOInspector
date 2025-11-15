import Foundation

@testable import ISOInspectorKit

struct InMemoryRandomAccessReader: RandomAccessReader {
  let data: Data

  var length: Int64 { Int64(data.count) }

  func read(at offset: Int64, count: Int) throws -> Data {
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
    let rangeResult = offset.addingReportingOverflow(count64)
    guard rangeResult.overflow == false else {
      throw RandomAccessReaderError.overflowError
    }

    let lower = Int(offset)
    guard lower >= 0, lower <= data.count else {
      throw RandomAccessReaderError.boundsError(
        .requestedRangeOutOfBounds(offset: offset, count: count)
      )
    }

    let requestedUpper = rangeResult.partialValue
    guard requestedUpper >= 0 else {
      throw RandomAccessReaderError.boundsError(
        .requestedRangeOutOfBounds(offset: offset, count: count)
      )
    }

    let cappedUpper = min(length, requestedUpper)
    let lowerIndex = lower
    let upperIndex = lowerIndex + Int(cappedUpper - offset)

    return data.subdata(in: lowerIndex..<upperIndex)
  }
}
