import Foundation

extension StructuredPayload {
    struct TrackFragmentHeaderDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let trackID: UInt32
        let baseDataOffset: UInt64?
        let sampleDescriptionIndex: UInt32?
        let defaultSampleDuration: UInt32?
        let defaultSampleSize: UInt32?
        let defaultSampleFlags: UInt32?
        let durationIsEmpty: Bool
        let defaultBaseIsMoof: Bool

        init(box: ParsedBoxPayload.TrackFragmentHeaderBox) {
            self.version = box.version
            self.flags = box.flags
            self.trackID = box.trackID
            self.baseDataOffset = box.baseDataOffset
            self.sampleDescriptionIndex = box.sampleDescriptionIndex
            self.defaultSampleDuration = box.defaultSampleDuration
            self.defaultSampleSize = box.defaultSampleSize
            self.defaultSampleFlags = box.defaultSampleFlags
            self.durationIsEmpty = box.durationIsEmpty
            self.defaultBaseIsMoof = box.defaultBaseIsMoof
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case trackID = "track_ID"
            case baseDataOffset = "base_data_offset"
            case sampleDescriptionIndex = "sample_description_index"
            case defaultSampleDuration = "default_sample_duration"
            case defaultSampleSize = "default_sample_size"
            case defaultSampleFlags = "default_sample_flags"
            case durationIsEmpty = "duration_is_empty"
            case defaultBaseIsMoof = "default_base_is_moof"
        }
    }
}
