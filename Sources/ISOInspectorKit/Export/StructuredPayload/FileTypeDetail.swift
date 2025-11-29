import Foundation

extension StructuredPayload {
    struct FileTypeDetail: Encodable {
        let majorBrand: String
        let minorVersion: UInt32
        let compatibleBrands: [String]
        
        init(box: ParsedBoxPayload.FileTypeBox) {
            self.majorBrand = box.majorBrand.rawValue
            self.minorVersion = box.minorVersion
            self.compatibleBrands = box.compatibleBrands.map(\.rawValue)
        }
        
        private enum CodingKeys: String, CodingKey {
            case majorBrand = "major_brand"
            case minorVersion = "minor_version"
            case compatibleBrands = "compatible_brands"
        }
    }
}
