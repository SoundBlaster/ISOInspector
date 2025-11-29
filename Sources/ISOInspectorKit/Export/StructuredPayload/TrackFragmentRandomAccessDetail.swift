import Foundation

extension StructuredPayload {
    struct TrackFragmentRandomAccessDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let trackID: UInt32
        let trafNumberLength: UInt8
        let trunNumberLength: UInt8
        let sampleNumberLength: UInt8
        let entryCount: UInt32
        let entries: [TrackFragmentRandomAccessEntryDetail]

        init(box: ParsedBoxPayload.TrackFragmentRandomAccessBox) {
            self.version = box.version
            self.flags = box.flags
            self.trackID = box.trackID
            self.trafNumberLength = box.trafNumberLength
            self.trunNumberLength = box.trunNumberLength
            self.sampleNumberLength = box.sampleNumberLength
            self.entryCount = box.entryCount
            self.entries = box.entries.map(TrackFragmentRandomAccessEntryDetail.init)
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case trackID = "track_ID"
            case trafNumberLength = "traf_number_length_bytes"
            case trunNumberLength = "trun_number_length_bytes"
            case sampleNumberLength = "sample_number_length_bytes"
            case entryCount = "entry_count"
            case entries
        }
    }
}
