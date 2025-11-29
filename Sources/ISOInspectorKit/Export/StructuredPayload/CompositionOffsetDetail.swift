import Foundation

extension StructuredPayload {
    struct CompositionOffsetDetail: Encodable {
        struct Entry: Encodable {
            let index: UInt32
            let sampleCount: UInt32
            let sampleOffset: Int32
            let byteRange: ByteRange

            init(entry: ParsedBoxPayload.CompositionOffsetBox.Entry) {
                self.index = entry.index
                self.sampleCount = entry.sampleCount
                self.sampleOffset = entry.sampleOffset
                self.byteRange = ByteRange(range: entry.byteRange)
            }

            private enum CodingKeys: String, CodingKey {
                case index
                case sampleCount = "sample_count"
                case sampleOffset = "sample_offset"
                case byteRange = "byte_range"
            }
        }

        let version: UInt8
        let flags: UInt32
        let entryCount: UInt32
        let entries: [Entry]

        init(box: ParsedBoxPayload.CompositionOffsetBox) {
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
