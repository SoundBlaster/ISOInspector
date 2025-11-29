import Foundation

extension StructuredPayload {
    struct SyncSampleTableDetail: Encodable {
        struct Entry: Encodable {
            let index: UInt32
            let sampleNumber: UInt32
            let byteRange: ByteRange

            init(entry: ParsedBoxPayload.SyncSampleTableBox.Entry) {
                self.index = entry.index
                self.sampleNumber = entry.sampleNumber
                self.byteRange = ByteRange(range: entry.byteRange)
            }

            private enum CodingKeys: String, CodingKey {
                case index
                case sampleNumber = "sample_number"
                case byteRange = "byte_range"
            }
        }

        let version: UInt8
        let flags: UInt32
        let entryCount: UInt32
        let entries: [Entry]

        init(box: ParsedBoxPayload.SyncSampleTableBox) {
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
