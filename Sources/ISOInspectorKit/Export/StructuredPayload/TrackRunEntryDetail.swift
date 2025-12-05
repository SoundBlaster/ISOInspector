import Foundation

extension StructuredPayload {
    struct TrackRunEntryDetail: Encodable {
        let index: UInt32
        let decodeTime: UInt64?
        let presentationTime: Int64?
        let sampleDuration: UInt32?
        let sampleSize: UInt32?
        let sampleFlags: UInt32?
        let sampleCompositionTimeOffset: Int32?
        let dataOffset: UInt64?
        let byteRange: ByteRange?

        init(entry: ParsedBoxPayload.TrackRunBox.Entry) {
            self.index = entry.index
            self.decodeTime = entry.decodeTime
            self.presentationTime = entry.presentationTime
            self.sampleDuration = entry.sampleDuration
            self.sampleSize = entry.sampleSize
            self.sampleFlags = entry.sampleFlags
            self.sampleCompositionTimeOffset = entry.sampleCompositionTimeOffset
            self.dataOffset = entry.dataOffset
            if let range = entry.byteRange {
                self.byteRange = ByteRange(range: range)
            } else {
                self.byteRange = nil
            }
        }

        private enum CodingKeys: String, CodingKey {
            case index
            case decodeTime = "decode_time"
            case presentationTime = "presentation_time"
            case sampleDuration = "sample_duration"
            case sampleSize = "sample_size"
            case sampleFlags = "sample_flags"
            case sampleCompositionTimeOffset = "sample_composition_time_offset"
            case dataOffset = "data_offset"
            case byteRange
        }
    }
}
