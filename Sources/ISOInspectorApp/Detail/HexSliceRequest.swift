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
#if canImport(ISOInspectorKit)
import ISOInspectorKit
#endif

struct HexSliceRequest: Equatable {
    struct Window: Equatable {
        let offset: Int64
        let length: Int
    }

    let header: BoxHeader
    let window: Window
}
