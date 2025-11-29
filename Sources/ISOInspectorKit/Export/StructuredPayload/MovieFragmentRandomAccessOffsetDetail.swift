import Foundation

extension StructuredPayload {
    struct MovieFragmentRandomAccessOffsetDetail: Encodable {
        let mfraSize: UInt32
        
        init(box: ParsedBoxPayload.MovieFragmentRandomAccessOffsetBox) {
            self.mfraSize = box.mfraSize
        }
        
        private enum CodingKeys: String, CodingKey {
            case mfraSize = "mfra_size"
        }
    }
}
