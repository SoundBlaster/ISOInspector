import Foundation

extension StructuredPayload {
    struct TrackExtendsDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let trackID: UInt32
        let defaultSampleDescriptionIndex: UInt32
        let defaultSampleDuration: UInt32
        let defaultSampleSize: UInt32
        let defaultSampleFlags: UInt32

        init(box: ParsedBoxPayload.TrackExtendsDefaultsBox) {
            self.version = box.version
            self.flags = box.flags
            self.trackID = box.trackID
            self.defaultSampleDescriptionIndex = box.defaultSampleDescriptionIndex
            self.defaultSampleDuration = box.defaultSampleDuration
            self.defaultSampleSize = box.defaultSampleSize
            self.defaultSampleFlags = box.defaultSampleFlags
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case trackID = "track_ID"
            case defaultSampleDescriptionIndex = "default_sample_description_index"
            case defaultSampleDuration = "default_sample_duration"
            case defaultSampleSize = "default_sample_size"
            case defaultSampleFlags = "default_sample_flags"
        }
    }
}
