import Foundation

public struct JSONParseTreeExporter {
    private let encoder: JSONEncoder
    
    public init(encoder: JSONEncoder = JSONEncoder()) {
        let configured = encoder
        configured.outputFormatting.insert(.sortedKeys)
        self.encoder = configured
    }
    
    public func export(tree: ParseTree) throws -> Data {
        let payload = StructuredPayload.Payload(tree: tree)
        return try encoder.encode(payload)
    }
}
