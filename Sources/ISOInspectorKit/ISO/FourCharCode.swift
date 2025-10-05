import Foundation

public enum FourCharCodeError: Swift.Error, Equatable {
    case invalidLength(Int)
    case invalidASCII(Data)
}

public struct FourCharCode: Equatable, Hashable, CustomStringConvertible {
    public let rawValue: String

    public init(_ value: String) throws {
        guard value.utf8.count == 4 else {
            throw FourCharCodeError.invalidLength(value.utf8.count)
        }
        self.rawValue = value
    }

    public init(data: Data) throws {
        guard data.count == 4 else {
            throw FourCharCodeError.invalidLength(data.count)
        }
        guard let string = String(data: data, encoding: .ascii) else {
            throw FourCharCodeError.invalidASCII(data)
        }
        try self.init(string)
    }

    public var description: String { rawValue }
}
