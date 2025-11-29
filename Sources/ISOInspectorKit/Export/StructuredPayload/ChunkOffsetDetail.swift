import Foundation

extension StructuredPayload {
    struct ChunkOffsetDetail: Encodable {
        enum Width: String, Encodable {
            case bits32 = "32"
            case bits64 = "64"
        }

        struct Entry: Encodable {
            let index: UInt32
            let offset: UInt64
            let byteRange: ByteRange

            init(entry: ParsedBoxPayload.ChunkOffsetBox.Entry) {
                self.index = entry.index
                self.offset = entry.offset
                self.byteRange = ByteRange(range: entry.byteRange)
            }
        }

        let version: UInt8
        let flags: UInt32
        let entryCount: UInt32
        let width: Width
        let entries: [Entry]

        init(box: ParsedBoxPayload.ChunkOffsetBox) {
            self.version = box.version
            self.flags = box.flags
            self.entryCount = box.entryCount
            switch box.width {
            case .bits32:
                self.width = .bits32
            case .bits64:
                self.width = .bits64
            }
            self.entries = box.entries.map(Entry.init)
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case entryCount = "entry_count"
            case width
            case entries
        }
    }
}
