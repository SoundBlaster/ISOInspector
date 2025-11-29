import Foundation

extension StructuredPayload {
    struct MovieHeaderDetail: Encodable {
        let version: UInt8
        let creationTime: UInt64
        let modificationTime: UInt64
        let timescale: UInt32
        let duration: UInt64
        let durationIs64Bit: Bool
        let rate: Double
        let volume: Double
        let matrix: MatrixDetail
        let nextTrackID: UInt32
        
        init(box: ParsedBoxPayload.MovieHeaderBox) {
            self.version = box.version
            self.creationTime = box.creationTime
            self.modificationTime = box.modificationTime
            self.timescale = box.timescale
            self.duration = box.duration
            self.durationIs64Bit = box.durationIs64Bit
            self.rate = box.rate
            self.volume = box.volume
            self.matrix = MatrixDetail(matrix: box.matrix)
            self.nextTrackID = box.nextTrackID
        }
        
        private enum CodingKeys: String, CodingKey {
            case version
            case creationTime = "creation_time"
            case modificationTime = "modification_time"
            case timescale
            case duration
            case durationIs64Bit = "duration_is_64bit"
            case rate
            case volume
            case matrix
            case nextTrackID = "next_track_id"
        }
    }
}
