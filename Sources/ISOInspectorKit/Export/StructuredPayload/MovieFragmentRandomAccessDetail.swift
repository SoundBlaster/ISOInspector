import Foundation

extension StructuredPayload {
    struct MovieFragmentRandomAccessDetail: Encodable {
        let tracks: [MovieFragmentRandomAccessTrackDetail]
        let totalEntryCount: Int
        let offset: MovieFragmentRandomAccessOffsetDetail?

        init(box: ParsedBoxPayload.MovieFragmentRandomAccessBox) {
            self.tracks = box.tracks.map(MovieFragmentRandomAccessTrackDetail.init)
            self.totalEntryCount = box.totalEntryCount
            if let offset = box.offset {
                self.offset = MovieFragmentRandomAccessOffsetDetail(box: offset)
            } else {
                self.offset = nil
            }
        }

        private enum CodingKeys: String, CodingKey {
            case tracks
            case totalEntryCount = "total_entry_count"
            case offset
        }
    }
}
