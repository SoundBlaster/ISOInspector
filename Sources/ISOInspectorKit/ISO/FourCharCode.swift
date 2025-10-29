import Foundation

public enum FourCharCodeError: Swift.Error, Equatable {
    case invalidLength(Int)
    case invalidASCII(Data)
}

extension ISOInspectorKit {
    public struct IIFourCharCode: Equatable, Hashable, CustomStringConvertible, Sendable {
        public let rawValue: String

        public init(_ value: String) throws {
            let scalarCount = value.unicodeScalars.count
            guard scalarCount == 4 else {
                throw FourCharCodeError.invalidLength(scalarCount)
            }
            self.rawValue = value
        }

        public init(data: Data) throws {
            guard data.count == 4 else {
                throw FourCharCodeError.invalidLength(data.count)
            }
            let string =
                String(data: data, encoding: .ascii)
                ?? String(data: data, encoding: .isoLatin1)
            guard let value = string else {
                throw FourCharCodeError.invalidASCII(data)
            }
            try self.init(value)
        }

        public var description: String { rawValue }
    }
}

public typealias IIFourCharCode = ISOInspectorKit.IIFourCharCode
