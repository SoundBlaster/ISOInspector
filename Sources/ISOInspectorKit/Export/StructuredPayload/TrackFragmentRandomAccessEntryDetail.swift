import Foundation

extension StructuredPayload {
    struct TrackFragmentRandomAccessEntryDetail: Encodable {
        let index: UInt32
        let time: UInt64
        let moofOffset: UInt64
        let trafNumber: UInt64
        let trunNumber: UInt64
        let sampleNumber: UInt64
        let fragmentSequenceNumber: UInt32?
        let trackID: UInt32?
        let sampleDescriptionIndex: UInt32?
        let runIndex: UInt32?
        let firstSampleGlobalIndex: UInt64?
        let resolvedDecodeTime: UInt64?
        let resolvedPresentationTime: Int64?
        let resolvedDataOffset: UInt64?
        let resolvedSampleSize: UInt32?
        let resolvedSampleFlags: UInt32?
        
        init(entry: ParsedBoxPayload.TrackFragmentRandomAccessBox.Entry) {
            self.index = entry.index
            self.time = entry.time
            self.moofOffset = entry.moofOffset
            self.trafNumber = entry.trafNumber
            self.trunNumber = entry.trunNumber
            self.sampleNumber = entry.sampleNumber
            self.fragmentSequenceNumber = entry.fragmentSequenceNumber
            self.trackID = entry.trackID
            self.sampleDescriptionIndex = entry.sampleDescriptionIndex
            self.runIndex = entry.runIndex
            self.firstSampleGlobalIndex = entry.firstSampleGlobalIndex
            self.resolvedDecodeTime = entry.resolvedDecodeTime
            self.resolvedPresentationTime = entry.resolvedPresentationTime
            self.resolvedDataOffset = entry.resolvedDataOffset
            self.resolvedSampleSize = entry.resolvedSampleSize
            self.resolvedSampleFlags = entry.resolvedSampleFlags
        }
        
        private enum CodingKeys: String, CodingKey {
            case index
            case time
            case moofOffset = "moof_offset"
            case trafNumber = "traf_number"
            case trunNumber = "trun_number"
            case sampleNumber = "sample_number"
            case fragmentSequenceNumber = "fragment_sequence_number"
            case trackID = "track_ID"
            case sampleDescriptionIndex = "sample_description_index"
            case runIndex = "run_index"
            case firstSampleGlobalIndex = "first_sample_global_index"
            case resolvedDecodeTime = "resolved_decode_time"
            case resolvedPresentationTime = "resolved_presentation_time"
            case resolvedDataOffset = "resolved_data_offset"
            case resolvedSampleSize = "resolved_sample_size"
            case resolvedSampleFlags = "resolved_sample_flags"
        }
    }
}
