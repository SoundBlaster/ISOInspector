import Foundation

struct HexSlice: Equatable {
    let offset: Int64
    let bytes: Data

    var endOffset: Int64 {
        offset + Int64(bytes.count)
    }

    var isEmpty: Bool {
        bytes.isEmpty
    }
}
