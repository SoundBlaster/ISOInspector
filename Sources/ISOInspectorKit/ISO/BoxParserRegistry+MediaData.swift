import Foundation

extension BoxParserRegistry.DefaultParsers {
    static func mediaData(header: BoxHeader, reader _: RandomAccessReader) throws -> ParsedBoxPayload? {
        let payloadRange = header.payloadRange
        guard payloadRange.lowerBound <= payloadRange.upperBound else { return nil }
        let detail = ParsedBoxPayload.MediaDataBox(
            headerStartOffset: header.startOffset,
            headerEndOffset: header.endOffset,
            totalSize: header.totalSize,
            payloadRange: payloadRange
        )
        return ParsedBoxPayload(fields: [], detail: .mediaData(detail))
    }
}
