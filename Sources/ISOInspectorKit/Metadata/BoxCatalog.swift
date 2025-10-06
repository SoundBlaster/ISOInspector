import Foundation

public struct BoxDescriptor: Equatable, Sendable {
    public struct Identifier: Equatable, Hashable, Sendable {
        public let type: FourCharCode
        public let extendedType: UUID?
    }

    public let identifier: Identifier
    public let name: String
    public let summary: String
    public let specification: String?
    public let version: Int?
    public let flags: UInt32?

    init(identifier: Identifier, name: String, summary: String, specification: String?, version: Int?, flags: UInt32?) {
        self.identifier = identifier
        self.name = name
        self.summary = summary
        self.specification = specification
        self.version = version
        self.flags = flags
    }
}

public struct BoxCatalog: Sendable {
    private let byType: [FourCharCode: BoxDescriptor]
    private let byExtendedType: [UUID: BoxDescriptor]

    public init(entries: [BoxDescriptor]) {
        var typeMap: [FourCharCode: BoxDescriptor] = [:]
        var extendedMap: [UUID: BoxDescriptor] = [:]
        for descriptor in entries {
            if let uuid = descriptor.identifier.extendedType {
                extendedMap[uuid] = descriptor
            } else {
                typeMap[descriptor.identifier.type] = descriptor
            }
        }
        self.byType = typeMap
        self.byExtendedType = extendedMap
    }

    public init() {
        self.init(entries: [])
    }

    public func descriptor(for header: BoxHeader) -> BoxDescriptor? {
        if let uuid = header.uuid, let descriptor = byExtendedType[uuid] {
            return descriptor
        }
        return byType[header.type]
    }
}

extension BoxCatalog {
    // @todo #2 Automate refreshing MP4RABoxes.json from the upstream registry and document the update workflow.
    static func loadBundledCatalog(logger: DiagnosticsLogger = DiagnosticsLogger(subsystem: "ISOInspectorKit", category: "BoxCatalog")) throws -> BoxCatalog {
        let loader = CatalogLoader(logger: logger)
        let entries = try loader.loadEntries()
        return BoxCatalog(entries: entries)
    }

    public static let shared: BoxCatalog = {
        do {
            return try BoxCatalog.loadBundledCatalog()
        } catch {
            loggerForShared().error("Failed to load MP4RA catalog: \(String(describing: error))")
            return BoxCatalog()
        }
    }()

    private static func loggerForShared() -> DiagnosticsLogger {
        DiagnosticsLogger(subsystem: "ISOInspectorKit", category: "BoxCatalog")
    }
}

private struct CatalogLoader {
    struct Registry: Decodable {
        struct Entry: Decodable {
            let type: String
            let uuid: String?
            let name: String
            let summary: String
            let specification: String?
            let version: Int?
            let flags: String?
        }

        let boxes: [Entry]
    }

    let logger: DiagnosticsLogger?

    init(logger: DiagnosticsLogger?) {
        self.logger = logger
    }

    func loadEntries() throws -> [BoxDescriptor] {
        guard let url = Bundle.module.url(forResource: "MP4RABoxes", withExtension: "json") else {
            throw CatalogLoadingError.missingResource
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let registry = try decoder.decode(Registry.self, from: data)
        return registry.boxes.compactMap { entry in
            do {
                return try makeDescriptor(from: entry)
            } catch {
                logger?.error("Failed to decode MP4RA entry for type \(entry.type): \(String(describing: error))")
                return nil
            }
        }
    }

    private func makeDescriptor(from entry: Registry.Entry) throws -> BoxDescriptor {
        let type = try FourCharCode(entry.type)
        let uuid = try entry.uuid.map { uuidString -> UUID in
            guard let value = UUID(uuidString: uuidString) else {
                throw CatalogLoadingError.invalidUUID(uuidString)
            }
            return value
        }
        let identifier = BoxDescriptor.Identifier(type: type, extendedType: uuid)
        let flags = try entry.flags.map { flagString -> UInt32 in
            guard let value = UInt32(flagString, radix: 16) else {
                throw CatalogLoadingError.invalidFlags(flagString)
            }
            return value
        }
        return BoxDescriptor(
            identifier: identifier,
            name: entry.name,
            summary: entry.summary,
            specification: entry.specification,
            version: entry.version,
            flags: flags
        )
    }
}

enum CatalogLoadingError: Swift.Error, Equatable {
    case missingResource
    case invalidUUID(String)
    case invalidFlags(String)
}
