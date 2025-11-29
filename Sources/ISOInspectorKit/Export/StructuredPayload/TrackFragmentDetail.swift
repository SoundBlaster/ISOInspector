import Foundation

extension StructuredPayload {
    struct TrackFragmentDetail: Encodable {
        let trackID: UInt32?
        let sampleDescriptionIndex: UInt32?
        let baseDataOffset: UInt64?
        let defaultSampleDuration: UInt32?
        let defaultSampleSize: UInt32?
        let defaultSampleFlags: UInt32?
        let durationIsEmpty: Bool
        let defaultBaseIsMoof: Bool
        let baseDecodeTime: UInt64?
        let baseDecodeTimeIs64Bit: Bool
        let runs: [TrackRunDetail]
        let totalSampleCount: UInt64
        let totalSampleSize: UInt64?
        let totalSampleDuration: UInt64?
        let earliestPresentationTime: Int64?
        let latestPresentationTime: Int64?
        let firstDecodeTime: UInt64?
        let lastDecodeTime: UInt64?

        init(box: ParsedBoxPayload.TrackFragmentBox) {
            self.trackID = box.trackID
            self.sampleDescriptionIndex = box.sampleDescriptionIndex
            self.baseDataOffset = box.baseDataOffset
            self.defaultSampleDuration = box.defaultSampleDuration
            self.defaultSampleSize = box.defaultSampleSize
            self.defaultSampleFlags = box.defaultSampleFlags
            self.durationIsEmpty = box.durationIsEmpty
            self.defaultBaseIsMoof = box.defaultBaseIsMoof
            self.baseDecodeTime = box.baseDecodeTime
            self.baseDecodeTimeIs64Bit = box.baseDecodeTimeIs64Bit
            self.runs = box.runs.map(TrackRunDetail.init)
            self.totalSampleCount = box.totalSampleCount
            self.totalSampleSize = box.totalSampleSize
            self.totalSampleDuration = box.totalSampleDuration
            self.earliestPresentationTime = box.earliestPresentationTime
            self.latestPresentationTime = box.latestPresentationTime
            self.firstDecodeTime = box.firstDecodeTime
            self.lastDecodeTime = box.lastDecodeTime
        }

        private enum CodingKeys: String, CodingKey {
            case trackID = "track_ID"
            case sampleDescriptionIndex = "sample_description_index"
            case baseDataOffset = "base_data_offset"
            case defaultSampleDuration = "default_sample_duration"
            case defaultSampleSize = "default_sample_size"
            case defaultSampleFlags = "default_sample_flags"
            case durationIsEmpty = "duration_is_empty"
            case defaultBaseIsMoof = "default_base_is_moof"
            case baseDecodeTime = "base_decode_time"
            case baseDecodeTimeIs64Bit = "base_decode_time_is_64bit"
            case runs
            case totalSampleCount = "total_sample_count"
            case totalSampleSize = "total_sample_size"
            case totalSampleDuration = "total_sample_duration"
            case earliestPresentationTime = "earliest_presentation_time"
            case latestPresentationTime = "latest_presentation_time"
            case firstDecodeTime = "first_decode_time"
            case lastDecodeTime = "last_decode_time"
        }
    }
}
