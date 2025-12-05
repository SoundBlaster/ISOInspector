import Foundation

extension StructuredPayload {
    struct CompactSampleSizeDetail: Encodable {
        struct Entry: Encodable {
            let index: UInt32
            let size: UInt32
            let byteRange: ByteRange

            init(entry: ParsedBoxPayload.CompactSampleSizeBox.Entry) {
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
        let fieldSize: UInt8
        let sampleCount: UInt32
        let entries: [Entry]

        init(box: ParsedBoxPayload.CompactSampleSizeBox) {
            self.version = box.version
            self.flags = box.flags
            self.fieldSize = box.fieldSize
            self.sampleCount = box.sampleCount
            self.entries = box.entries.map(Entry.init)
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case fieldSize = "field_size"
            case sampleCount = "sample_count"
            case entries
        }
    }
}
