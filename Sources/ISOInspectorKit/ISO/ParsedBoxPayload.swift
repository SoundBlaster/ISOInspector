import Foundation

public struct ParsedBoxPayload: Equatable, Sendable {
    public enum Detail: Equatable, Sendable {
        case fileType(FileTypeBox)
    }

    public struct FileTypeBox: Equatable, Sendable {
        public let majorBrand: FourCharCode
        public let minorVersion: UInt32
        public let compatibleBrands: [FourCharCode]

        public init(majorBrand: FourCharCode, minorVersion: UInt32, compatibleBrands: [FourCharCode]) {
            self.majorBrand = majorBrand
            self.minorVersion = minorVersion
            self.compatibleBrands = compatibleBrands
        }
    }

    public struct Field: Equatable, Sendable {
        public let name: String
        public let value: String
        public let description: String?
        public let byteRange: Range<Int64>?

        public init(
            name: String,
            value: String,
            description: String? = nil,
            byteRange: Range<Int64>? = nil
        ) {
            self.name = name
            self.value = value
            self.description = description
            self.byteRange = byteRange
        }
    }

    public let fields: [Field]
    public let detail: Detail?

    public init(fields: [Field] = [], detail: Detail? = nil) {
        self.fields = fields
        self.detail = detail
    }

    public var isEmpty: Bool {
        fields.isEmpty
    }

    public var fileType: FileTypeBox? {
        guard case let .fileType(box) = detail else { return nil }
        return box
    }
}
