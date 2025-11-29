import Foundation

extension StructuredPayload {
    struct TrackFragmentDecodeTimeDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let baseMediaDecodeTime: UInt64
        let baseMediaDecodeTimeIs64Bit: Bool

        init(box: ParsedBoxPayload.TrackFragmentDecodeTimeBox) {
            self.version = box.version
            self.flags = box.flags
            self.baseMediaDecodeTime = box.baseMediaDecodeTime
            self.baseMediaDecodeTimeIs64Bit = box.baseMediaDecodeTimeIs64Bit
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case baseMediaDecodeTime = "base_media_decode_time"
            case baseMediaDecodeTimeIs64Bit = "base_media_decode_time_is_64bit"
        }
    }
}
