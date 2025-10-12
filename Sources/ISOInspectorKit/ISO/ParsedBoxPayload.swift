import Foundation

public struct ParsedBoxPayload: Equatable, Sendable {
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

    public init(fields: [Field] = []) {
        self.fields = fields
    }

    public var isEmpty: Bool {
        fields.isEmpty
    }
}
