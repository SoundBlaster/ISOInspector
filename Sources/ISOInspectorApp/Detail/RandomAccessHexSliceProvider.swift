import Foundation
import ISOInspectorKit

final class RandomAccessHexSliceProvider: HexSliceProvider {
  private let reader: RandomAccessReader

  init(reader: RandomAccessReader) {
    self.reader = reader
  }

  func loadSlice(for request: HexSliceRequest) async throws -> HexSlice {
    let data = try reader.read(at: request.window.offset, count: request.window.length)
    return HexSlice(offset: request.window.offset, bytes: data)
  }
}
