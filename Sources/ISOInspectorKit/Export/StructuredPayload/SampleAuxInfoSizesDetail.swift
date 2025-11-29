import Foundation

extension StructuredPayload {
    struct SampleAuxInfoSizesDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let defaultSampleInfoSize: UInt8
        let entryCount: UInt32
        let auxInfoType: String?
        let auxInfoTypeParameter: UInt32?
        let variableSizes: RangeSummary?

        init(box: ParsedBoxPayload.SampleAuxInfoSizesBox) {
            self.version = box.version
            self.flags = box.flags
            self.defaultSampleInfoSize = box.defaultSampleInfoSize
            self.entryCount = box.entryCount
            self.auxInfoType = box.auxInfoType?.rawValue
            self.auxInfoTypeParameter = box.auxInfoTypeParameter
            if let range = box.variableEntriesRange {
                self.variableSizes = RangeSummary(range: range, length: box.variableEntriesByteLength)
            } else {
                self.variableSizes = nil
            }
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case defaultSampleInfoSize = "default_sample_info_size"
            case entryCount = "entry_count"
            case auxInfoType = "aux_info_type"
            case auxInfoTypeParameter = "aux_info_type_parameter"
            case variableSizes = "variable_sizes"
        }
    }
}
