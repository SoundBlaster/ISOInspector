import Foundation

public struct BoxHeader: Equatable {
    public let type: FourCharCode
    public let totalSize: Int64
    public let headerSize: Int64
    public let payloadRange: Range<Int64>
    public let range: Range<Int64>
    public let uuid: UUID?

    public var startOffset: Int64 { range.lowerBound }
    public var endOffset: Int64 { range.upperBound }
}
