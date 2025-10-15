import Foundation
import ISOInspectorKit


struct ParseTreeNodeDetail: Equatable {
    let header: BoxHeader
    let metadata: BoxDescriptor?
    let payload: ParsedBoxPayload?
    let validationIssues: [ValidationIssue]
    let snapshotTimestamp: Date
    var hexSlice: HexSlice?
}
