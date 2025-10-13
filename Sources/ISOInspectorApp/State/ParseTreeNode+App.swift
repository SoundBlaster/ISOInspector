#if canImport(Combine)
import Foundation
import ISOInspectorKit

public typealias ParseTreeNode = ISOInspectorKit.ParseTreeNode

extension ISOInspectorKit.ParseTreeNode: Identifiable {
    public var id: Int64 { header.startOffset }

    public var category: BoxCategory {
        BoxClassifier.category(for: header, metadata: metadata)
    }

    public var isStreamingIndicator: Bool {
        BoxClassifier.isStreamingIndicator(header: header)
    }
}
#endif
