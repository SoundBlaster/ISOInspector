import Foundation
import ISOInspectorKit

struct HexSliceRequest: Equatable {
    struct Window: Equatable {
        let offset: Int64
        let length: Int
    }

    let header: BoxHeader
    let window: Window
}
