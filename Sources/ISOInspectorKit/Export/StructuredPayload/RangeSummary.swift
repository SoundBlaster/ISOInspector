import Foundation

extension StructuredPayload {
    struct RangeSummary: Encodable {
        let range: ByteRange
        let length: Int
        
        init(range: Range<Int64>, length: Int64?) {
            self.range = ByteRange(range: range)
            let resolved = length ?? (range.upperBound - range.lowerBound)
            if resolved <= 0 {
                self.length = 0
            } else if resolved >= Int64(Int.max) {
                self.length = Int.max
            } else {
                self.length = Int(resolved)
            }
        }
    }
}
