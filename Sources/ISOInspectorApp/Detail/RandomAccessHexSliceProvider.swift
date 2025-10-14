import Foundation
#if canImport(ISOInspectorKit_iOS)
import ISOInspectorKit_iOS
#endif
#if canImport(ISOInspectorKit_macOS)
import ISOInspectorKit_macOS
#endif
#if canImport(ISOInspectorKit_ipadOS)
import ISOInspectorKit_ipadOS
#endif

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
