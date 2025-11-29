import Foundation

extension StructuredPayload {
    struct TrackRunDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let sampleCount: UInt32
        let dataOffset: Int32?
        let firstSampleFlags: UInt32?
        let totalSampleDuration: UInt64?
        let totalSampleSize: UInt64?
        let startDecodeTime: UInt64?
        let endDecodeTime: UInt64?
        let startPresentationTime: Int64?
        let endPresentationTime: Int64?
        let startDataOffset: UInt64?
        let endDataOffset: UInt64?
        let trackID: UInt32?
        let sampleDescriptionIndex: UInt32?
        let runIndex: UInt32?
        let firstSampleGlobalIndex: UInt64?
        let entries: [TrackRunEntryDetail]

        init(box: ParsedBoxPayload.TrackRunBox) {
            self.version = box.version
            self.flags = box.flags
            self.sampleCount = box.sampleCount
            self.dataOffset = box.dataOffset
            self.firstSampleFlags = box.firstSampleFlags
            self.totalSampleDuration = box.totalSampleDuration
            self.totalSampleSize = box.totalSampleSize
            self.startDecodeTime = box.startDecodeTime
            self.endDecodeTime = box.endDecodeTime
            self.startPresentationTime = box.startPresentationTime
            self.endPresentationTime = box.endPresentationTime
            self.startDataOffset = box.startDataOffset
            self.endDataOffset = box.endDataOffset
            self.trackID = box.trackID
            self.sampleDescriptionIndex = box.sampleDescriptionIndex
            self.runIndex = box.runIndex
            self.firstSampleGlobalIndex = box.firstSampleGlobalIndex
            self.entries = box.entries.map(TrackRunEntryDetail.init)
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case sampleCount = "sample_count"
            case dataOffset = "data_offset"
            case firstSampleFlags = "first_sample_flags"
            case totalSampleDuration = "total_sample_duration"
            case totalSampleSize = "total_sample_size"
            case startDecodeTime = "start_decode_time"
            case endDecodeTime = "end_decode_time"
            case startPresentationTime = "start_presentation_time"
            case endPresentationTime = "end_presentation_time"
            case startDataOffset = "start_data_offset"
            case endDataOffset = "end_data_offset"
            case trackID = "track_ID"
            case sampleDescriptionIndex = "sample_description_index"
            case runIndex = "run_index"
            case firstSampleGlobalIndex = "first_sample_global_index"
            case entries
        }
    }
}
