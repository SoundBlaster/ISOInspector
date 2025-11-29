import Foundation

extension StructuredPayload {
    struct ByteRange: Encodable {
        let start: Int
        let end: Int
        
        init(range: Range<Int64>) {
            self.start = Int(range.lowerBound)
            self.end = Int(range.upperBound)
        }
    }
}
