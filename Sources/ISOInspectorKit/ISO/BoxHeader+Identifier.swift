import Foundation

extension BoxHeader {
    public var identifierString: String {
        if let uuid {
            return "uuid::\(uuid.uuidString.lowercased())"
        }
        return type.rawValue
    }
}
