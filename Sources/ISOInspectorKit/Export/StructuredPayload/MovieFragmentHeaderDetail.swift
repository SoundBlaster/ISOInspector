extension StructuredPayload {
    struct MovieFragmentHeaderDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let sequenceNumber: UInt32

        init(box: ParsedBoxPayload.MovieFragmentHeaderBox) {
            self.version = box.version
            self.flags = box.flags
            self.sequenceNumber = box.sequenceNumber
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case sequenceNumber = "sequence_number"
        }
    }
}
