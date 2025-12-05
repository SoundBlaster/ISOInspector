import Foundation

extension BoxParserRegistry.DefaultParsers {
    @Sendable static func mediaData(header: BoxHeader, reader _: RandomAccessReader) throws
        -> ParsedBoxPayload?
    {
        let payloadRange = header.payloadRange
        guard payloadRange.lowerBound <= payloadRange.upperBound else { return nil }
        let headerEndOffset = header.startOffset + header.headerSize
        let detail = ParsedBoxPayload.MediaDataBox(
            headerStartOffset: header.startOffset, headerEndOffset: headerEndOffset,
            totalSize: header.totalSize, payloadRange: payloadRange)
        return ParsedBoxPayload(fields: [], detail: .mediaData(detail))
    }

    @Sendable static func padding(header: BoxHeader, reader _: RandomAccessReader) throws
        -> ParsedBoxPayload?
    {
        let payloadRange = header.payloadRange
        guard payloadRange.lowerBound <= payloadRange.upperBound else { return nil }
        let headerEndOffset = header.startOffset + header.headerSize
        let detail = ParsedBoxPayload.PaddingBox(
            type: header.type, headerStartOffset: header.startOffset,
            headerEndOffset: headerEndOffset, totalSize: header.totalSize,
            payloadRange: payloadRange)
        return ParsedBoxPayload(fields: [], detail: .padding(detail))
    }
}
