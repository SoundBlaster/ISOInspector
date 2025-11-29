import Foundation

extension StructuredPayload {
    struct TimeToSampleDetail: Encodable {
        struct Entry: Encodable {
            let index: UInt32
            let sampleCount: UInt32
            let sampleDelta: UInt32
            let byteRange: ByteRange
            
            init(entry: ParsedBoxPayload.DecodingTimeToSampleBox.Entry) {
                self.index = entry.index
                self.sampleCount = entry.sampleCount
                self.sampleDelta = entry.sampleDelta
                self.byteRange = ByteRange(range: entry.byteRange)
            }
            
            private enum CodingKeys: String, CodingKey {
                case index
                case sampleCount = "sample_count"
                case sampleDelta = "sample_delta"
                case byteRange = "byte_range"
            }
        }
        
        let version: UInt8
        let flags: UInt32
        let entryCount: UInt32
        let entries: [Entry]
        
        init(box: ParsedBoxPayload.DecodingTimeToSampleBox) {
            self.version = box.version
            self.flags = box.flags
            self.entryCount = box.entryCount
            self.entries = box.entries.map(Entry.init)
        }
        
        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case entryCount = "entry_count"
            case entries
        }
    }
}
