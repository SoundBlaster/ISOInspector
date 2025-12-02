import Foundation

extension StructuredPayload {
    struct Sizes: Encodable {
        let total: Int
        let header: Int
        let payload: Int

        init(header: BoxHeader) {
            self.total = Int(header.totalSize)
            self.header = Int(header.headerSize)
            self.payload = max(
                0, Int(header.payloadRange.upperBound - header.payloadRange.lowerBound))
        }
    }
}
