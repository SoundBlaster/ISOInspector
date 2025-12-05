import Foundation

extension StructuredPayload {
    struct MovieFragmentRandomAccessTrackDetail: Encodable {
        let trackID: UInt32
        let entryCount: Int
        let earliestTime: UInt64?
        let latestTime: UInt64?
        let fragments: [UInt32]

        init(summary: ParsedBoxPayload.MovieFragmentRandomAccessBox.TrackSummary) {
            self.trackID = summary.trackID
            self.entryCount = summary.entryCount
            self.earliestTime = summary.earliestTime
            self.latestTime = summary.latestTime
            self.fragments = summary.referencedFragmentSequenceNumbers
        }

        private enum CodingKeys: String, CodingKey {
            case trackID = "track_ID"
            case entryCount = "entry_count"
            case earliestTime = "earliest_time"
            case latestTime = "latest_time"
            case fragments
        }
    }
}
