import Foundation

public struct BoxHeader: Equatable, Sendable {
    public let type: FourCharCode
    public let totalSize: Int64
    public let headerSize: Int64
    public let payloadRange: Range<Int64>
    public let range: Range<Int64>
    public let uuid: UUID?

    public var startOffset: Int64 { range.lowerBound }
    public var endOffset: Int64 { range.upperBound }

    public init(
        type: FourCharCode,
        totalSize: Int64,
        headerSize: Int64,
        payloadRange: Range<Int64>,
        range: Range<Int64>,
        uuid: UUID?
    ) {
        self.type = type
        self.totalSize = totalSize
        self.headerSize = headerSize
        self.payloadRange = payloadRange
        self.range = range
        self.uuid = uuid
    }
}
