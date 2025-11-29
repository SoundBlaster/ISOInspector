import Foundation

extension StructuredPayload {
    struct SampleAuxInfoOffsetsDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let entryCount: UInt32
        let auxInfoType: String?
        let auxInfoTypeParameter: UInt32?
        let entrySizeBytes: Int
        let entries: RangeSummary?

        init(box: ParsedBoxPayload.SampleAuxInfoOffsetsBox) {
            self.version = box.version
            self.flags = box.flags
            self.entryCount = box.entryCount
            self.auxInfoType = box.auxInfoType?.rawValue
            self.auxInfoTypeParameter = box.auxInfoTypeParameter
            self.entrySizeBytes = box.entrySizeBytes
            if let range = box.entriesRange {
                self.entries = RangeSummary(range: range, length: box.entriesByteLength)
            } else {
                self.entries = nil
            }
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case entryCount = "entry_count"
            case auxInfoType = "aux_info_type"
            case auxInfoTypeParameter = "aux_info_type_parameter"
            case entrySizeBytes = "entry_size_bytes"
            case entries
        }
    }
}
