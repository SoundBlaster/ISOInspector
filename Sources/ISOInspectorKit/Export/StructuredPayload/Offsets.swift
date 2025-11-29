import Foundation

extension StructuredPayload {
    struct Offsets: Encodable {
        let start: Int
        let end: Int
        let payloadStart: Int
        let payloadEnd: Int
        
        init(header: BoxHeader) {
            self.start = Int(header.range.lowerBound)
            self.end = Int(header.range.upperBound)
            self.payloadStart = Int(header.payloadRange.lowerBound)
            self.payloadEnd = Int(header.payloadRange.upperBound)
        }
    }
}
