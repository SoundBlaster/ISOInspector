import Foundation

extension StructuredPayload {
    struct PayloadField: Encodable {
        let name: String
        let value: String
        let summary: String?
        let byteRange: ByteRange?
        
        init(field: ParsedBoxPayload.Field) {
            self.name = field.name
            self.value = field.value
            self.summary = field.description
            if let range = field.byteRange {
                self.byteRange = ByteRange(range: range)
            } else {
                self.byteRange = nil
            }
        }
    }
}
