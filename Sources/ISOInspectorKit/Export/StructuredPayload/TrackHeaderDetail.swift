import Foundation

extension StructuredPayload {
    struct TrackHeaderDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let creationTime: UInt64
        let modificationTime: UInt64
        let trackID: UInt32
        let duration: UInt64
        let durationIs64Bit: Bool
        let layer: Int16
        let alternateGroup: Int16
        let volume: Double
        let matrix: MatrixDetail
        let width: Double
        let height: Double
        let isEnabled: Bool
        let isInMovie: Bool
        let isInPreview: Bool
        let isZeroSized: Bool
        let isZeroDuration: Bool
        
        init(box: ParsedBoxPayload.TrackHeaderBox) {
            self.version = box.version
            self.flags = box.flags
            self.creationTime = box.creationTime
            self.modificationTime = box.modificationTime
            self.trackID = box.trackID
            self.duration = box.duration
            self.durationIs64Bit = box.durationIs64Bit
            self.layer = box.layer
            self.alternateGroup = box.alternateGroup
            self.volume = box.volume
            self.matrix = MatrixDetail(matrix: box.matrix)
            self.width = box.width
            self.height = box.height
            self.isEnabled = box.isEnabled
            self.isInMovie = box.isInMovie
            self.isInPreview = box.isInPreview
            self.isZeroSized = box.isZeroSized
            self.isZeroDuration = box.isZeroDuration
        }
        
        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case creationTime = "creation_time"
            case modificationTime = "modification_time"
            case trackID = "track_id"
            case duration
            case durationIs64Bit = "duration_is_64bit"
            case layer
            case alternateGroup = "alternate_group"
            case volume
            case matrix
            case width
            case height
            case isEnabled = "is_enabled"
            case isInMovie = "is_in_movie"
            case isInPreview = "is_in_preview"
            case isZeroSized = "is_zero_sized"
            case isZeroDuration = "is_zero_duration"
        }
    }
}
