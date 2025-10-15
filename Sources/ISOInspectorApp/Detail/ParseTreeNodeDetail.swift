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

struct ParseTreeNodeDetail: Equatable {
    let header: BoxHeader
    let metadata: BoxDescriptor?
    let payload: ParsedBoxPayload?
    let validationIssues: [ValidationIssue]
    let snapshotTimestamp: Date
    var hexSlice: HexSlice?
}
