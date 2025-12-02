import Foundation

final class MetadataEnvironmentCoordinator: @unchecked Sendable {
    private struct Context {
        var handlerType: HandlerType?
        var keyTable: [UInt32: ParsedBoxPayload.MetadataKeyTableBox.Entry] = [:]
    }

    private var stack: [Context] = []

    func willStartBox(header: BoxHeader) {
        if header.type == BoxType.metadata { stack.append(Context()) }
    }

    func didParsePayload(header: BoxHeader, payload: ParsedBoxPayload?) {
        guard !stack.isEmpty else { return }
        switch header.type {
        case BoxType.handler:
            guard
                let codeString = payload?.fields.first(where: { $0.name == "handler_type" })?.value,
                let code = try? FourCharCode(codeString)
            else { return }
            stack[stack.count - 1].handlerType = HandlerType(code: code)
        case BoxType.keys:
            if let table = payload?.metadataKeyTable {
                var mapping: [UInt32: ParsedBoxPayload.MetadataKeyTableBox.Entry] = [:]
                for entry in table.entries { mapping[entry.index] = entry }
                stack[stack.count - 1].keyTable = mapping
            }
        default: break
        }
    }

    func environment(for header: BoxHeader) -> BoxParserRegistry.MetadataEnvironment {
        guard let context = stack.last else { return BoxParserRegistry.MetadataEnvironment() }
        switch header.type {
        case BoxType.metadata, BoxType.keys, BoxType.itemList:
            return BoxParserRegistry.MetadataEnvironment(
                handlerType: context.handlerType, keyTable: context.keyTable)
        default: return BoxParserRegistry.MetadataEnvironment()
        }
    }

    func didFinishBox(header: BoxHeader) {
        if header.type == BoxType.metadata { _ = stack.popLast() }
    }

    private enum BoxType {
        static let metadata = try! FourCharCode("meta")
        static let handler = try! FourCharCode("hdlr")
        static let keys = try! FourCharCode("keys")
        static let itemList = try! FourCharCode("ilst")
    }
}
