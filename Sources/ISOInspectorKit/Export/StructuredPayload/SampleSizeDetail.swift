import Foundation

extension StructuredPayload {
    struct SampleSizeDetail: Encodable {
        struct Entry: Encodable {
            let index: UInt32
            let size: UInt32
            let byteRange: ByteRange
            
            init(entry: ParsedBoxPayload.SampleSizeBox.Entry) {
                self.index = entry.index
                self.size = entry.size
                self.byteRange = ByteRange(range: entry.byteRange)
            }
            
            private enum CodingKeys: String, CodingKey {
                case index
                case size
                case byteRange = "byte_range"
            }
        }
        
        let version: UInt8
        let flags: UInt32
        let defaultSampleSize: UInt32
        let sampleCount: UInt32
        let isConstant: Bool
        let entries: [Entry]
        
        init(box: ParsedBoxPayload.SampleSizeBox) {
            self.version = box.version
            self.flags = box.flags
            self.defaultSampleSize = box.defaultSampleSize
            self.sampleCount = box.sampleCount
            self.isConstant = box.isConstant
            self.entries = box.entries.map(Entry.init)
        }
        
        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case defaultSampleSize = "default_sample_size"
            case sampleCount = "sample_count"
            case isConstant = "is_constant"
            case entries
        }
    }
}
