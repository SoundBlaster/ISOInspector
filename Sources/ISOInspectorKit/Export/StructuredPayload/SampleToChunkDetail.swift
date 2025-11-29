import Foundation

extension StructuredPayload {
    struct SampleToChunkDetail: Encodable {
        struct Entry: Encodable {
            let firstChunk: UInt32
            let samplesPerChunk: UInt32
            let sampleDescriptionIndex: UInt32
            let byteRange: ByteRange

            init(entry: ParsedBoxPayload.SampleToChunkBox.Entry) {
                self.firstChunk = entry.firstChunk
                self.samplesPerChunk = entry.samplesPerChunk
                self.sampleDescriptionIndex = entry.sampleDescriptionIndex
                self.byteRange = ByteRange(range: entry.byteRange)
            }

            private enum CodingKeys: String, CodingKey {
                case firstChunk = "first_chunk"
                case samplesPerChunk = "samples_per_chunk"
                case sampleDescriptionIndex = "sample_description_index"
                case byteRange = "byte_range"
            }
        }

        let version: UInt8
        let flags: UInt32
        let entries: [Entry]

        init(box: ParsedBoxPayload.SampleToChunkBox) {
            self.version = box.version
            self.flags = box.flags
            self.entries = box.entries.map(Entry.init)
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case entries
        }
    }
}
